require 'chef/knife'
#TODO: Testing of everything
#TODO: All inputs MUST be checked and errors MUST be catched.
class Chef
  class Knife
    module ProxmoxBase
      
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'rubygems'
            require 'rest_client'
            require 'json'
            require 'chef/json_compat'
            require 'cgi'
            require 'chef/log'
            require 'set'
            require 'net/ssh/multi'
            require 'chef/api_client'
            require 'chef/node'
            require 'readline'
            require 'chef/knife/bootstrap'
            Chef::Knife::Bootstrap.load_deps
          end
          
          # options
          option :pve_cluster_url,
            :short => "-U URL",
            :long  => "--pve_cluster_url URL",
            :description => "Your URL to access Proxmox VE server/cluster",
            :proc  => Proc.new {|url| Chef::Config[:knife][:pve_cluster_url] = url }
            
          option :pve_user_name,
            :short => "-u username",
            :long  => "--username username",
            :description => "Your username in Proxmox VE",
            :proc  => Proc.new {|username| Chef::Config[:knife][:pve_user_name] = username }
            
          option :pve_user_password,
            :short => "-p password",
            :long  => "--password password",
            :description => "Your password in Proxmox VE",
            :proc  => Proc.new {|password| Chef::Config[:knife][:pve_user_password] = password }
            
          option :pve_user_realm,
            :short => "-r realm",
            :long  => "--realm realm",
            :description => "Your realm of Authentication in Proxmox VE",
            :proc  => Proc.new {|realm| Chef::Config[:knife][:pve_user_realm] = realm }
            
          option :pve_node_name,
            :short => "-n node",
            :long  => "--node nodename",
            :description => "Proxmox VE server name where you will actuate",
            :proc  => Proc.new {|node| Chef::Config[:knife][:pve_node_name] = node }

          option :pve_vm_type,
            :short => "-t type",
            :long  => "--type vm_type",
            :description => "The type of vm you'd like to control",
            :proc  => Proc.new {|type| Chef::Config[:knife][:pve_vm_type] = type }
          
        end
      end
      
      # Checks that the parameter provided is defined in knife.rb
      def check_global_parameter(value)
        if (Chef::Config[:knife][value].nil? or Chef::Config[:knife][value].empty?) then
          ui.error "knife[:#{value.to_s}] is empty, define a value for it and try again"
          exit 1
        end
        Chef::Log.debug("knife[:#{value}] = " + Chef::Config[:knife][value])
      end
      
      def check_config_parameter(value)
        if (config[value].nil? or config[value].empty?) then
          ui.error "--#{value} is empty, define a value for it and try again"
          exit 1
        end
      end
      
      # Establishes the connection with proxmox server
      def connection
        # First, let's check we have all info needed to connect to pve
        [:pve_cluster_url, :pve_node_name, :pve_user_name, :pve_user_password, :pve_user_realm].each do |value|
          check_global_parameter(value)
        end
        
        @connection ||= RestClient::Resource.new(Chef::Config[:knife][:pve_cluster_url])
        @auth_params ||= begin
          token = nil
          csrf_prevention_token = nil
          @connection['access/ticket'].post :username=>Chef::Config[:knife][:pve_user_name],
            :realm=>Chef::Config[:knife][:pve_user_realm],
            :password=>Chef::Config[:knife][:pve_user_password] do |response, request, result, &block| 
            if response.code == 200 then
              data = JSON.parse(response.body)
              ticket = data['data']['ticket']
              csrf_prevention_token = data['data']['CSRFPreventionToken']
              if !ticket.nil? then
                token = 'PVEAuthCookie=' + ticket.gsub!(/:/,'%3A').gsub!(/=/,'%3D')
              end
            end
          end
          {:CSRFPreventionToken => csrf_prevention_token, :cookie => token} 
        end
      end
      
      # new_vmid: calculates a new vmid from the highest existing vmid
      def new_vmid
        vmid ||= @connection['cluster/resources?type=vm'].get @auth_params do |response, request, result, &block|
          data = JSON.parse(response.body)['data']
          vmids = Set[]
          data.each {|entry|
            vmids.add entry['vmid']
          }
          (vmids.empty? ? 100 : (vmids.max + 1)).to_s
        end
      end

      # locate_config_value: find a value in arguments or default chef config properties
      def locate_config_value(key)
        key = key.to_sym
        Chef::Config[:knife][key] || config[key]
      end
      
      # template_number_to_name: converts the id from the template list to the real name in the storage
      # of the node
      def template_number_to_name(number,storage)
        template_list = []
        #TODO: esta parte hay que sacarla a un modulo comun de acceso a templates
        @connection["nodes/#{Chef::Config[:knife][:pve_node_name]}/storage/#{storage}/content"].get @auth_params do |response, request, result, &block|
          JSON.parse(response.body)['data'].each { |entry|
            if entry['content'] == 'vztmpl' then
              template_list << entry['volid']
            end
          }
        end
        return CGI.escape(template_list[number.to_i])
      end
      
      # server_name_to_vmid: Use the name of the server to get the vmid
      def server_name_to_vmid(name)
        @connection['cluster/resources?type=vm'].get @auth_params do |response, request, result, &block|
          data = JSON.parse(response.body)['data']
          data.each {|entry|
            return entry['vmid'] if entry['name'].to_s.match(name)
          }
        end
      end
      
      # vmid_to_node: Specify the vmid and get the node in which is. nil otherwise
      def vmid_to_node(vmid)
        node = nil
        @connection['cluster/resources?type=vm'].get @auth_params do |response, request, result, &block|
          data = JSON.parse(response.body)['data']
          data.each {|entry|
            if entry['vmid'].to_s.match(vmid.to_s) then
              node = entry['node'] 
            end
          }
          return node
        end
      end
      
      def action_response(action,response)
        result = nil
        taskid = nil
        begin
          if (response.code == 200) then
            result = "OK"
          else
            result = "Error: #{response.code.to_s} - #{response.body}"
          end
          taskid = JSON.parse(response.body)['data']
          waitfor(taskid)
          Chef::Log.debug("Action: #{action}, Result: #{result}\n")
        rescue Exception => msg
          result = "An exception ocurred.  Use -VV to show it"
          Chef::Log.debug("Action: #{action}, Result: #{msg}\n")
        end
        ui.msg(result)
      end
      
      # waitfor end of the task, need the taskid and the timeout
      def waitfor(taskid, timeout=60)
        taskstatus = nil
        while taskstatus.nil? and timeout>= 0 do
          print "."
          @connection["nodes/#{Chef::Config[:knife][:pve_node_name]}/tasks/#{taskid}/status"].get @auth_params do |response, request, result, &block|
            taskstatus = (JSON.parse(response.body)['data']['status'] == "stopped")?true:nil
          end
          timeout-=1
          sleep(1)
        end
      end
      
      # server_start: Starts the server
      def server_start(vmid, type)
        node = vmid_to_node(vmid)
        ui.msg("Starting VM #{vmid} on node #{node} of #{type}....")
        if type == "qemu"
          @connection["nodes/#{node}/qemu/#{vmid}/status/start"].post "", @auth_params do |response, request, result, &block|
            # take the response and extract the taskid
            action_response("server start",response)
          end
        elsif type == "openvz"
          @connection["nodes/#{node}/openvz/#{vmid}/status/start"].post "", @auth_params do |response, request, result, &block|
            # take the response and extract the taskid
            action_response("server start",response)
          end
        else
          puts "Invalid server type!"
          exit 1
        end
      end
      
      # server_stop: Stops the server
      def server_stop(vmid)
        node = vmid_to_node(vmid)
        ui.msg("Stopping VM #{vmid} on node #{node}...")
        @connection["nodes/#{node}/openvz/#{vmid}/status/stop"].post "", @auth_params do |response, request, result, &block|
          # take the response and extract the taskid
          action_response("server stop",response)
        end
        # TODO: check with server_get_data the status/current/status of the vmid to send the umount command
        rescue Exception => e
          ui.warn("The VMID does not match any node")
          exit 1
      end
      
      # server_unmount: Unmounts the server's filesystem
      def server_umount(vmid)
        node = vmid_to_node(vmid)
        ui.msg("Unmounting VM #{vmid} on node #{node}...")
        @connection["nodes/#{node}/openvz/#{vmid}/status/umount"].post "", @auth_params do |response, request, result, &block|
          # take the response and extract the taskid
          action_response("server umount",response)
        end
        rescue Exception => e
          ui.warn("The VMID does not match any node")
          exit 1
      end

      
      # server_create: Sends a vm_definition to proxmox for creation
      def server_create(vmid,vm_definition)
        ui.msg("Creating VM #{vmid}...")
        @connection["nodes/#{Chef::Config[:knife][:pve_node_name]}/openvz"].post "#{vm_definition}", @auth_params do |response, request, result, &block|
          action_response("server create",response)
        end
      end
      
      # server_get_address: Returns the IP Address of the machine to chef
      # field is a string, and if it doesn't exist, it will return nil
      def server_get_data(vmid,field)
        node = vmid_to_node(vmid)
        @connection["nodes/#{node}/openvz/#{vmid}/status/current"].get @auth_params do |response, request, result, &block|
          #action_response("server get data",response)
          # (field.match('all'))?JSON.parse(response.body)['data'].to_json : JSON.parse(response.body)['data'][field]
          if (field == 'all') then
            JSON.parse(response.body)['data']
          else
            JSON.parse(response.body)['data'][field]
          end
        end
      end
      
      # server_destroy: Destroys the server
      def server_destroy(vmid)
        node = vmid_to_node(vmid)
        ui.msg("Destroying VM #{vmid} on node #{node}...")
        @connection["nodes/#{node}/openvz/#{vmid}"].delete @auth_params do |response, request, result, &block|
          action_response("server destroy",response)
        end
      end
      
      # Extracted from Chef::Knife.delete_object, because it has a
      # confirmation step built in... By specifying the '--purge'
      # flag (and also explicitly confirming the server destruction!)
      # the user is already making their intent known.  It is not
      # necessary to make them confirm two more times.
      def destroy_item(klass, name, type_name)
        begin
          object = klass.load(name)
          object.destroy
          ui.warn("Deleted #{type_name} #{name}")
        rescue Net::HTTPServerException
          ui.warn("Could not find a #{type_name} named #{name} to delete!")
        end
      end
      
      
      
      
    end # module
  end # class 
end # class

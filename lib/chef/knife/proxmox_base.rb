require 'chef/knife'

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

        end
      end

      def connection
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

      #
      # Generic functions
      #

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

      def vmid_to_type(vmid)
        @connection['cluster/resources?type=vm'].get @auth_params do |response, request, result, &block|
          data = JSON.parse(response.body)['data']
          return data.find {|d| d['vmid'] == vmid.to_i }['type']
        end
      end

      def locate_config_value(key)
        key = key.to_sym
        Chef::Config[:knife][key] || config[key]
      end

      def template_number_to_name(number,storage)
        template_list = []
        @connection["nodes/#{Chef::Config[:knife][:pve_node_name]}/storage/#{storage}/content"].get @auth_params do |response, request, result, &block|
          JSON.parse(response.body)['data'].each { |entry|
            if entry['content'] == 'vztmpl' then
              template_list << entry['volid']
            end
          }
        end
        return CGI.escape(template_list[number.to_i])
      end

      def server_name_to_vmid(name)
        @connection['cluster/resources?type=vm'].get @auth_params do |response, request, result, &block|
          data = JSON.parse(response.body)['data']
          data.each {|entry|
            return entry['vmid'] if entry['name'].to_s.match(name)
          }
        end
      end
      
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
          if (response.code != 200) then
            result = "Error: #{response.code.to_s} - #{response.body}"
          end
          taskid = JSON.parse(response.body)['data']
          waitfor(taskid)
          Chef::Log.debug("Action: #{action}, Result: #{result}\n")
        rescue Exception => msg
          result = "An exception ocurred.  Use -VV to show it"
          Chef::Log.debug("Action: #{action}, Result: #{msg}\n")
        end
      end

      def waitfor(taskid, timeout=60)
        taskstatus = nil
        while taskstatus.nil? and timeout>= 0 do
          @connection["nodes/#{Chef::Config[:knife][:pve_node_name]}/tasks/#{taskid}/status"].get @auth_params do |response, request, result, &block|
            taskstatus = (JSON.parse(response.body)['data']['status'] == "stopped")?true:nil
          end
          timeout-=1
          sleep(1)
        end
      end

      def destroy_item(klass, name, type_name)
        begin
          object = klass.load(name)
          object.destroy
          ui.warn("Deleted #{type_name} #{name}")
        rescue Net::HTTPServerException
          ui.warn("Could not find a #{type_name} named #{name} to delete!")
        end
      end

      #
      # VM Functions
      #

      def vm_create(vmid, type, vm_definition)
        ui.msg("Creating VM #{vmid}...")
        @connection["nodes/#{Chef::Config[:knife][:pve_node_name]}/#{type}"].post "#{vm_definition}", @auth_params do |response, request, result, &block|
          action_response("server create",response)
        end
      end

      def vm_delete(vmid)
        ui.msg("Deleting VM #{vmid}...")
        @connection["nodes/#{Chef::Config[:knife][:pve_node_name]}/#{vmid_to_type(vmid)}/#{vmid}"].delete @auth_params do |response, request, result, &block|
          action_response("qemu delete",response)
        end
      end

      def vm_start(vmid)
        node = vmid_to_node(vmid)
        ui.msg("Starting VM #{vmid} on node #{node}...")
        @connection["nodes/#{node}/#{vmid_to_type(vmid)}/#{vmid}/status/start"].post "", @auth_params do |response, request, result, &block|
          action_response("server start",response)
        end
        rescue Exception => e
          ui.warn("The VMID does not match any node")
          exit 1
      end
      
      def vm_stop(vmid)
        node = vmid_to_node(vmid)
        ui.msg("Stopping VM #{vmid}...")
        @connection["nodes/#{node}/#{vmid_to_type(vmid)}/#{vmid}/status/stop"].post "", @auth_params do |response, request, result, &block|
          action_response("server stop",response)
        end
        rescue Exception => e
          ui.warn("The VMID does not match any node")
          exit 1
      end      

      def vm_info(vmid, field)
        @connection["nodes/#{Chef::Config[:knife][:pve_node_name]}/#{vmid_to_type(vmid)}/#{vmid}/status/current"].get @auth_params do |response, request, result, &block|
          if field == 'all'
            JSON.parse(response.body)['data']
          else
            JSON.parse(response.body)['data'][field]
          end
        end
      end
      
    end # module
  end # class 
end # class

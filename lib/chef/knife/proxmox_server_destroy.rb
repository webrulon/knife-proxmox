require 'chef/knife/proxmox_base'


class Chef
  class Knife
    class ProxmoxServerDestroy < Knife
      include Knife::ProxmoxBase

      banner "knife proxmox server destroy (options)"

      # Options for this action
      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the Rackspace node itself. Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        :short => "-H hostname",
        :long => "--hostname hostname",
        :description => "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."
        
      option :vm_id,
        :short => "-I number",
        :long  => "--vmid number",
        :description => "The numeric identifier of the VM"

      option :force,
        :short => "-y",
        :long  => "--yes",
        :description => "Force answer to yes (useful for scripting)"

      def run
        # Needed
        connection
        
        #TODO: must detect which parameter has been used: name or vmid
        vm_id = nil
        if (config[:vm_id].nil? and config[:chef_node_name].nil?) then
          ui.error("You must use -I <id> or -H <Hostname>")
          exit 1
        elsif (!config[:chef_node_name].nil?)
            name = config[:chef_node_name]
            vm_id = server_name_to_vmid(name)
            puts "Server to destroy: #{name} [vmid: #{vm_id}]"
            if (config[:force].nil?) then
              ui.confirm("Continue")
            end
        else
          vm_id = config[:vm_id]
        end
        
        begin
          server_stop(vm_id)
          ui.msg("Preparing the server to delete")
          sleep(5)
          server_destroy(vm_id)
        rescue Exception => e
          ui.warn("Error trying to destroy the server. Does the server exists?")
          exit 1
        end
        
        #TODO: remove server from chef
        if config[:purge]
          thing_to_delete = config[:chef_node_name] || server_get_data(config[:vm_id],"name")
          destroy_item(Chef::Node, thing_to_delete, "node")
          destroy_item(Chef::ApiClient, thing_to_delete, "client")
        else
          ui.warn("Corresponding node and client for the #{vm_id} server were not deleted and remain registered with the Chef Server")
        end
      end
      
    end
  end
end

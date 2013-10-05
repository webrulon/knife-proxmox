require 'chef/knife/proxmox_base'


class Chef
  class Knife
    class ProxmoxServerInfo < Knife

      include Knife::ProxmoxBase

      banner "knife proxmox server info (options)"

      option :chef_node_name,
        :short => "-H hostname",
        :long => "--hostname hostname",
        :description => "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."
        
      option :vm_id,
        :short => "-I number",
        :long  => "--vmid number",
        :description => "The numeric identifier of the VM"

      option :parameter,
        :short => "-P parameter",
        :long  => "--parameter name",
        :description => "The field you are requesting (\"all\" for all data)"


      def run
        # Needed
        connection
        
        vm_id = nil
        name = nil
        if (config[:vm_id].nil? and config[:chef_node_name].nil?) then
          ui.error("You must use -I <id> or -H <Hostname>")
          exit 1
        elsif (!config[:chef_node_name].nil?)
            name = config[:chef_node_name]
            vm_id = server_name_to_vmid(name)
        else
          vm_id = config[:vm_id]
        end
        
        parameter = config[:parameter] || 'all'
        
        data = server_get_data(vm_id,parameter)
        ui.output(data)
      end
    end
  end
end
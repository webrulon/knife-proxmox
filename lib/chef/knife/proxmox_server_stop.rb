require 'chef/knife/proxmox_base'


class Chef
  class Knife
    class ProxmoxServerStop < Knife

      include Knife::ProxmoxBase

      banner "knife proxmox server stop (options)"

      option :vm_id,
        :short => "-I number",
        :long  => "--vmid number",
        :description => "The numeric identifier of the VM"

      def run
        # Needed
        connection
        
        check_config_parameter(:vm_id)
        
        server_stop(config[:vm_id])
        
      end
    end
  end
end

require 'chef/knife/proxmox_base'


class Chef
  class Knife
    class ProxmoxServerStart < Knife

      include Knife::ProxmoxBase

      banner "knife proxmox server start (options)"

      option :vm_id,
        :short => "-I number",
        :long  => "--vmid number",
        :description => "The numeric identifier of the VM"

      def run
        # Needed
        connection
        
        check_config_parameter(:vm_id)
        
        server_start(config[:vm_id])
      end
    end
  end
end
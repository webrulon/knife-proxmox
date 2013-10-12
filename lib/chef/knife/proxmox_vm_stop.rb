require 'chef/knife/proxmox_base'


class Chef
  class Knife
    class ProxmoxVmStop < Knife

      include Knife::ProxmoxBase

      banner "knife proxmox vm stop (options)"

      option :vm_id,
        :short => "-I ID",
        :long  => "--vm_id ID",
        :description => "The numeric identifier of the VM"
      
      def run
        connection
        
        [:vm_id].each do |param|
          check_config_parameter(param)
        end

        vm_stop(config[:vm_id])
        
      end
    end
  end
end

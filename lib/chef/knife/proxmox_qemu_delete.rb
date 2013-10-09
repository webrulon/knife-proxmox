require 'chef/knife/proxmox_base'

class Chef
  class Knife
    class ProxmoxQemuDelete < Knife
      
      include Knife::ProxmoxBase
      
      banner "knife proxmox qemu delete (options)"
      
      option :vmid,
        :short => "-i vmid",
        :long  => "--vmid vmid",
        :description => "VM ID"

      def run
        connection

        [:vmid].each do |param|
          check_config_parameter(param)
        end

        vm_config = Hash.new
        vm_config[:vmid]        = config[:vmid]     ||= new_vmid

        qemu_delete(vm_config[:vmid])
        ui.msg("Deleting VM with ID #{vm_config[:vmid]}")              
      end
      
    end
  end
end

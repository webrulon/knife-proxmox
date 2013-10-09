require 'chef/knife/proxmox_base'


class Chef
  class Knife
    class ProxmoxQemuInfo < Knife

      include Knife::ProxmoxBase

      banner "knife proxmox qemu info (options)"

      option :vm_id,
        :short => "-I vm_id",
        :long  => "--vmid vm_id",
        :description => "The numeric identifier of the VM"

      def run
        connection

        [:vm_id].each do |param|
          check_config_parameter(param)
        end

        data = qemu_info(config[:vm_id])

        ui.output(data)

      end
    end
  end
end

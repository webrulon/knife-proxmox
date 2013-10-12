require 'chef/knife/proxmox_base'


class Chef
  class Knife
    class ProxmoxVmInfo < Knife

      include Knife::ProxmoxBase

      banner "knife proxmox vm info (options)"

      option :vm_id,
        :short => "-I ID",
        :long  => "--vm_id ID",
        :description => "The numeric identifier of the VM"

      option :field,
        :short => "-f field",
        :long  => "--field field",
        :description => "Which field to extract from the output"

      def run
        connection

        [:vm_id].each do |param|
          check_config_parameter(param)
        end

        field = config[:field] ||= "all"

        data = vm_info(config[:vm_id], field)

        ui.output(data)

      end
    end
  end
end

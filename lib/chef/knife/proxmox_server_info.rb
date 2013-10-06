require 'chef/knife/proxmox_base'


class Chef
  class Knife
    class ProxmoxServerInfo < Knife

      include Knife::ProxmoxBase

      banner "knife proxmox server info (options)"

      option :vm_id,
        :short => "-I number",
        :long  => "--vmid number",
        :description => "The numeric identifier of the VM"

      option :pve_vm_type,
        :short => "-t type",
        :long  => "--type vm type",
        :description => "The type of vm you want to control (qemu or openvz)"

      option :parameter,
        :short => "-P parameter",
        :long  => "--parameter name",
        :description => "The field you are requesting (\"all\" for all data)"


      def run
        connection
        [:vm_id, :pve_vm_type].each do |param|
          check_config_parameter(param)
        end

        parameter = config[:parameter] || 'all'
        
        data = server_info(config[:vm_id], config[:pve_vm_type], parameter)
        ui.output(data)
      end
    end
  end
end

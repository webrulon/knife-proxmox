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
      
      option :pve_vm_type,
        :short => "-t type",
        :long  => "--type vm type",
        :description => "The type of vm you want to control (qemu or openvz)"

      def run
        connection
        
        [:vm_id, :pve_vm_type].each do |param|
          check_config_parameter(param)
        end
        
        server_stop(config[:vm_id], config[:pve_vm_type])
        
      end
    end
  end
end

require 'chef/knife/proxmox_base'

class Chef
  class Knife
    class ProxmoxQemuCreate < Knife
      
      include Knife::ProxmoxBase
      
      banner "knife proxmox qemu create (options)"
      
      option :name,
        :short => "-n name",
        :long  => "--name name",
        :description => "VM name"

      option :cdrom,
        :short => "-c local:iso/filename.iso",
        :long  => "--cdrom local:iso/filename.iso",
        :description => "ISO to mount to cdrom drive"

      def run
        # Needed
        connection

        #required arguments
        # [:pve_vm_type].each do |param|
        #   check_config_parameter(param)
        # end
        vm_config = Hash.new
        vm_config[:vmid]        = config[:vmid]     ||= new_vmid
        vm_config[:sockets]     = config[:sockets]     ||= 1
        vm_config[:memory]      = config[:memory]   ||= 512
        vm_config[:name]        = config[:name] ||= "proxmox"
        vm_config[:cdrom]       = config[:cdrom] ||= ""

        #puts vm_iso

        vm_definition = vm_config.to_a.map { |v| v.join '=' }.join '&'
        puts vm_definition
        qemu_create(vm_config[:vmid], vm_definition)
        ui.msg("Starting #{vm_config[:name]} with ID #{vm_config[:vmid]}")
        #server_start(vm_id)
        sleep(5)
        
      #   # which IP address to bootstrap
      #   bootstrap_ip_address = server_get_data(vm_id,'ip')
      #   ui.msg("New Server #{vm_id} has IP Address: #{bootstrap_ip_address}")
        
      #   if bootstrap_ip_address.nil?
      #     ui.error("No IP address available for bootstrapping.")
      #     exit 1
      #   end

      #   print(".") until tcp_test_ssh(bootstrap_ip_address) {
      #     sleep @initial_sleep_delay ||= 10
      #     puts("done")
      #   }

      #   # bootstrapping the node
      #   if config[:bootstrap]
      #     bootstrap_for_node(bootstrap_ip_address).run
      #   else
      #     ui.msg("Skipping bootstrap of the server because --no-bootstrap used as argument.")   
      #   end 
      
      end
      
      # def tcp_test_ssh(hostname)
      #   tcp_socket = TCPSocket.new(hostname, 22)
      #   readable = IO.select([tcp_socket], nil, nil, 5)
      #   if readable
      #     Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
      #     yield
      #     true
      #   else
      #     false
      #   end
      # rescue Errno::ETIMEDOUT
      #   false
      # rescue Errno::EPERM
      #   false
      # rescue Errno::ECONNREFUSED
      #   sleep 2
      #   false
      # rescue Errno::EHOSTUNREACH
      #   sleep 2
      #   false
      # ensure
      #   tcp_socket && tcp_socket.close
      # end

      # def bootstrap_for_node(bootstrap_ip_address)
      #   require 'chef/knife/bootstrap'
      #   Chef::Knife::Bootstrap.load_deps
      #   bootstrap = Chef::Knife::Bootstrap.new
      #   bootstrap.name_args = [bootstrap_ip_address]
      #   bootstrap.config[:run_list] = config[:run_list]
      #   bootstrap.config[:environment] = locate_config_value(:environment)
      #   # bootstrap.config[:first_boot_attributes] = config[:first_boot_attributes]
      #   bootstrap.config[:ssh_user] = "root"
      #   bootstrap.config[:ssh_password] = config[:vm_password]
      #   # bootstrap.config[:identity_file] = config[:identity_file]
      #   # bootstrap.config[:host_key_verify] = config[:host_key_verify]
      #   bootstrap.config[:chef_node_name] = config[:vm_hostname]
      #   # bootstrap.config[:prerelease] = config[:prerelease]
      #   bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
      #   bootstrap.config[:distro] = locate_config_value(:distro)
      #   # bootstrap will run as root...sudo (by default) also messes up Ohai on CentOS boxes
      #   # bootstrap.config[:use_sudo] = false
      #   bootstrap.config[:template_file] = locate_config_value(:template_file)
        
      #   pp bootstrap.config
      #   bootstrap
      # end
    end
  end
end

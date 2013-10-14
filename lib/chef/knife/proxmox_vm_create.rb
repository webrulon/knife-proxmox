require 'chef/knife/proxmox_base'

class Chef
  class Knife
    class ProxmoxVmCreate < Knife
      
      include Knife::ProxmoxBase
      
      banner "knife proxmox vm create (options)"
      
      option :hostname,
        :short => "-h hostname",
        :long  => "--hostname hostname",
        :description => "(OpenVZ|QEMU) - Sets the hostname in OpenVZ and VM name for QEMU"

      option :os_template,
        :short => "-o template",
        :long  => "--os_template template",
        :description => "(OpenVZ) - Sets the OS template in OpenVZ"

      option :cpu,
        :short => "-z 1",
        :long  => "--cpu 1",
        :description => "(OpenVZ|QEMU) - Number of CPUs to allocate to VM."

      option :memory,
        :short => "-m 512",
        :long  => "--memory 512",
        :description => "(OpenVZ|QEMU) - Amount of memory to allocate to VM."

      option :cdrom,
        :short => "-C local:iso/filename.iso",
        :long  => "--cdrom local:iso/filename.iso",
        :description => "(QEMU) - ISO to mount to cdrom drive"

      option :swap,
        :short => "-s 512",
        :long  => "--swap 512",
        :description => "(OpenVZ) - Set the available swap space for the container. Defaults to 1.5x of memory."

      option :password,
        :short => "-P password",
        :long  => "--vm_password password",
        :description => "(OpenVZ) - Root password to be set on the container"

      option :ip,
        :short => "-I 192.168.7.1",
        :long  => "--ip 192.168.1.1",
        :description => "(OpenVZ) - IP Address to set on the container"

      option :vm_type,
        :short => "-t type",
        :long => "--vm_type type",
        :description => "Which type of vm to create (openvz or qemu)"

      def run
        connection

        [:vm_type].each do |param|
          check_config_parameter(param)
        end

        vm_config = Hash.new

        if config[:vm_type] == "openvz"
          [:os_template].each do |param|
            check_config_parameter(param)
          end
          vm_config[:vmid]       = config[:vmid]         ||= new_vmid
          vm_config[:cpus]       = config[:cpu]          ||= 1
          vm_config[:memory]     = config[:memory]       ||= 512
          vm_config[:swap]       = config[:swap]         ||= (config[:memory] * 1.5).to_i
          vm_config[:hostname]   = config[:hostname]     ||= "proxmox"
          vm_config[:ostemplate] = config[:os_template]  ||= ""
          vm_config[:ip_address] = config[:ip]           if config[:ip]
          vm_config[:password]   = config[:password]     if config[:password]
        elsif config[:vm_type] == "qemu"
          vm_config[:vmid]       = config[:vmid]       ||= new_vmid
          vm_config[:sockets]    = config[:cpu]        ||= 1
          vm_config[:memory]     = config[:memory]     ||= 512
          vm_config[:name]       = config[:hostname]   ||= "proxmox" 
          vm_config[:cdrom]      = config[:cdrom]      if config[:cdrom]
          puts vm_config
        end
        puts vm_config
        vm_definition = vm_config.to_a.map { |v| v.join '=' }.join '&'
        vm_create(vm_config[:vmid], config[:vm_type], vm_definition)
        sleep(5)
        vm_start(vm_config[:vmid])

        
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

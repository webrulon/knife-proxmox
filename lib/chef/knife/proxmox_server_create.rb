require 'chef/knife/proxmox_base'

class Chef
  class Knife
    class ProxmoxServerCreate < Knife
      
      include Knife::ProxmoxBase
      
      banner "knife proxmox server create (options)"
      
      # TODO: parameters for openvz should be in other object
      option :vm_hostname,
        :short => "-H hostname",
        :long  => "--hostname hostname",
        :description => "VM instance hostname"

      option :vm_cpus,
        :short => "-C CPUs",
        :long  => "--cpus number",
        :description => "Number of cpus of the VM instance"

      option :vm_memory,
        :short => "-M MB",
        :long  => "--mem MB",
        :description => "Memory in MB"

      option :vm_swap,
        :short => "-SW",
        :long  => "--swap MB",
        :description => "Memory in MB for swap"

      option :vm_vmid,
        :short => "-I id",
        :long  => "--vmid id",
        :description => "Id for the VM"

      option :vm_disk,
        :short => "-D disk",
        :long  => "--disk GB",
        :description => "Disk space in GB"

      option :vm_storage,
        :short => "-ST name",
        :long  => "--storage name",
        :description => "Name of the storage where to reserve space"

      option :vm_password,
        :short => "-P password",
        :long  => "--vm_pass password",
        :description => "root password for VM (openvz only)",
        :default     => "proxmox"

      option :vm_netif,
        :short => "-N netif",
        :long  => "--netif netif_specification",
        :description => "description of the network interface (experimental)"

      option :vm_template,
        :short => "-T number",
        :long  => "--template number",
        :description => "id of the template"

      option :vm_ipaddress,
        :short => "-ip ipaddress",
        :long  => "--ipaddress IP Address",
        :description => "force guest to use venet interface with this ip address"

      option :bootstrap,
        :long => "--[no-]bootstrap",
        :description => "Bootstrap the server, enable by default",
        :boolean => true,
        :default => true
        
      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'chef-full'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "chef-full"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :first_boot_attributes,
        :short => "-j JSON_ATTRIBS",
        :long => "--json-attributes",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| JSON.parse(o) },
        :default => {}

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default",
        :boolean => true,
        :default => true

      option :environment,
        :short=> "-e environment",
        :long => "--environment environment",
        :description => "Chef environment",
        :proc => Proc.new {|env| Chef::Config[:knife][:environment] = env },
        :default => '_default'

      option :pve_vm_type,
        :short => "-t type",
        :long  => "--type vm type",
        :description => "The type of vm you want to control (qemu or openvz)"

      def run
        # Needed
        connection

        #required arguments
        [:pve_vm_type, :template_file].each do |param|
          check_config_parameter(param)
        end

        vm_config = Hash.new

        vm_id       = vm_config[:vmid]     ||= new_vmid
        vm_cpus     = vm_config[:sockets]     ||= 1
        vm_memory   = vm_config[:memory]   ||= 512

        #specific attrs for openvz
        if :pve_vm_type == "openvz"
          vm_hostname = vm_config[:vm_hostname] ||= "proxmox" 
          vm_swap     = vm_config[:vm_swap]     ||= 512
        #specific attrs for qemu
        elsif :pve_vm_type == "qemu"
          vm_name = vm_config[:name] ||= "proxmox"
        end


        vm_definition = vm_config.to_a.map { |v| v.join '=' }.join '&'

        server_create(vm_id, config[:pve_vm_type], vm_definition)
        ui.msg("Preparing the server to start")
        sleep(5)
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

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

      def run
        # Needed
        connection
        
        vm_id       = config[:vm_vmid]     || new_vmid
        vm_hostname = config[:vm_hostname] || 'proxmox'
        vm_storage  = config[:vm_storage]  || 'local'
        vm_password = config[:vm_password] || 'pve123'
        vm_cpus     = config[:vm_cpus]     || 1
        vm_memory   = config[:vm_memory]   || 512
        vm_disk     = config[:vm_disk]     || 4
        vm_swap     = config[:vm_swap]     || 512
        vm_ipaddress= config[:vm_ipaddress]|| nil
        vm_netif    = config[:vm_netif]    || 'ifname%3Deth0%2Cbridge%3Dvmbr0'
        vm_template = template_number_to_name(config[:vm_template],vm_storage) || 'local%3Avztmpl%2Fubuntu-11.10-x86_64-jorge2-.tar.gz'
        
        vm_definition = "vmid=#{vm_id}&hostname=#{vm_hostname}&storage=#{vm_storage}&password=#{vm_password}&ostemplate=#{vm_template}&memory=#{vm_memory}&swap=#{vm_swap}&disk=#{vm_disk}&cpus=#{vm_cpus}"
        
        # Add ip_address parameter to vm_definition if it's provided by CLI
        if (config[:vm_ipaddress]) then 
          vm_definition += "&ip_address=" + vm_ipaddress
        elsif (config[:vm_netif] || vm_netif) then
          vm_definition += "&netif=" + vm_netif
        end
        
        Chef::Log.debug(vm_definition)
        
        server_create(vm_id,vm_definition)
        ui.msg("Preparing the server to start")
        sleep(5)
        server_start(vm_id)
        sleep(5)
        
        # which IP address to bootstrap
        bootstrap_ip_address = server_get_data(vm_id,'ip')
        ui.msg("New Server #{vm_id} has IP Address: #{bootstrap_ip_address}")
        
        if bootstrap_ip_address.nil?
          ui.error("No IP address available for bootstrapping.")
          exit 1
        end

        print(".") until tcp_test_ssh(bootstrap_ip_address) {
          sleep @initial_sleep_delay ||= 10
          puts("done")
        }

        # bootstrapping the node
        if config[:bootstrap]
          bootstrap_for_node(bootstrap_ip_address).run
        else
          ui.msg("Skipping bootstrap of the server because --no-bootstrap used as argument.")   
        end 
      
      end
      
      def tcp_test_ssh(hostname)
        tcp_socket = TCPSocket.new(hostname, 22)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def bootstrap_for_node(bootstrap_ip_address)
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [bootstrap_ip_address]
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:environment] = locate_config_value(:environment)
        # bootstrap.config[:first_boot_attributes] = config[:first_boot_attributes]
        bootstrap.config[:ssh_user] = "root"
        bootstrap.config[:ssh_password] = config[:vm_password]
        # bootstrap.config[:identity_file] = config[:identity_file]
        # bootstrap.config[:host_key_verify] = config[:host_key_verify]
        bootstrap.config[:chef_node_name] = config[:vm_hostname]
        # bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:distro] = locate_config_value(:distro)
        # bootstrap will run as root...sudo (by default) also messes up Ohai on CentOS boxes
        # bootstrap.config[:use_sudo] = false
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        
        pp bootstrap.config
        bootstrap
      end
    end
  end
end

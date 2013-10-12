require 'chef/knife/proxmox_base'


class Chef
  class Knife
    class ProxmoxVmList < Knife

      include Knife::ProxmoxBase

      banner "knife proxmox vm list (options)"

      option :field,
             :short => "-f field",
             :field  => "--field field",
             :description => "Sort by field <field>"

      def run
        # Needed
        connection
        
        server_list = [
          ui.color('Id'  , :bold),
          ui.color('Node', :bold),
          ui.color('Name', :bold),
          ui.color('Type', :bold),
          ui.color('Status', :bold)
        ]

        field = config[:field] || 'vmid'

        @connection['cluster/resources?type=vm'].get @auth_params do |response, request, result, &block|
          JSON.parse(response.body)['data'].sort_by{ |entry| entry[field] }.each {|entry|
            vm_id = entry['vmid']
            type  = entry['type']
            server_list << vm_id.to_s
            server_list << entry['node']
            server_list << entry['name']
            server_list << type
            server_list << entry['status']
          }
        end
        puts ui.list(server_list, :uneven_columns_across, 5)
      end
    end
  end
end

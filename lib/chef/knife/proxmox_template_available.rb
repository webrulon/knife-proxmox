require 'chef/knife/proxmox_base'

class Chef
  class Knife
    class ProxmoxTemplateAvailable < Knife

      include Knife::ProxmoxBase

      banner "knife proxmox template available (options)"
      
      def run
        # Needed
        connection
        
        template_list = [
          ui.color('Name', :bold),
          ui.color('Operating System', :bold)
        ]
        
        @connection["nodes/#{Chef::Config[:knife][:pve_node_name]}/aplinfo"].get @auth_params do |response, request, result, &block|
          JSON.parse(response.body)['data'].each { |entry|
            template_list << entry['template'].strip
            template_list << entry['os'].strip
          }
        end

        puts ui.list(template_list, :uneven_columns_across, 2)
      end
    end
  end
end
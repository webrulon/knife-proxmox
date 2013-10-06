require 'chef/knife/proxmox_base'

class Chef
  class Knife
    class ProxmoxTemplateList < Knife
      
      include Knife::ProxmoxBase
      
      banner "knife proxmox template list (options)"
      
      def run
        # Needed to initialize @connection and @auth_params 
        connection
        
        template_list = [
          ui.color('Id'  , :bold),
          ui.color('Type', :bold),
          ui.color('Name', :bold),
          ui.color('Size', :bold)
        ]
        
        @connection["nodes/#{Chef::Config[:knife][:pve_node_name]}/storage/local/content"].get @auth_params do |response, request, result, &block|
          template_index = 0
          JSON.parse(response.body)['data'].each { |entry|
            if entry['content'] != 'iso' then
              template_list << template_index.to_s
              template_list << entry['format']
              template_list << entry['volid']
              template_list << (entry['size'].to_i/1048576).to_s + " MB"
              template_index+=1
            end
          }
        end
        puts ui.list(template_list, :uneven_columns_across, 4)
      end
    end
  end
end

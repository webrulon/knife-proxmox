require 'chef/knife/proxmox_base'

class Chef
  class Knife
    class ProxmoxIsoList < Knife
      
      include Knife::ProxmoxBase
      
      banner "knife proxmox iso list (options)"
      
      def run
        # Needed to initialize @connection and @auth_params 
        connection
        
        iso_list = [
          ui.color('Id'  , :bold),
          ui.color('Name', :bold),
          ui.color('Size', :bold)
        ]
        
        @connection["nodes/#{Chef::Config[:knife][:pve_node_name]}/storage/local/content"].get @auth_params do |response, request, result, &block|
          iso_index = 0
          JSON.parse(response.body)['data'].each { |entry|
            if entry['content'] == 'iso' then
              iso_list << iso_index.to_s
              iso_list << entry['volid']
              iso_list << (entry['size'].to_i/1048576).to_s + " MB"
              iso_index+=1
            end
          }
        end
        puts ui.list(iso_list, :uneven_columns_across, 3)
      end
    end
  end
end

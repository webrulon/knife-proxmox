require 'chef/knife/proxmox_base'


class Chef
  class Knife
    class ProxmoxNodeList < Knife

      include Knife::ProxmoxBase

      banner "knife proxmox node list (options)"

      def run
        connection

        node_list = [
          ui.color('#', :bold),
          ui.color('Id', :bold),
          ui.color('Name', :bold),
          ui.color('Free Mem', :bold),
          ui.color('Disk', :bold),
          ui.color('Uptime', :bold)
        ]

        @connection["cluster/resources?type=node"].get @auth_params do |response, request, result, &block|
          node_index = 1

          JSON.parse(response.body)['data'].each { |entry|
            node_list << node_index.to_s
            node_list << entry['id']
            node_list << entry['node']
            node_list << (entry['maxmem'].to_i/1024/1024*0.001 - entry['mem'].to_i/1024/1024*0.001).round(2).to_s + "GB"
            node_list << (entry['disk'].to_i/1048576).to_s + " GB"
            node_list << (entry['uptime'].to_i/86400).to_s + " Days"
            node_index+=1
          }
        end
        puts ui.list(node_list, :uneven_columns_across, 6)
      end
    end
  end
end

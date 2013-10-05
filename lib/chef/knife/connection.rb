# This class should be a singleton with all the logic to use proxmox

class Connection
  
  @site = nil
  @auth_params = nil
  @servers = {}
  @templates = {}
  
  def initialize()
    @site = RestClient::Resource.new(Chef::Config[:knife][:pve_cluster_url])
    @auth_params ||= begin
      ticket = nil
      csrf_prevention_token = nil
      @site['access/ticket'].post :username=>Chef::Config[:knife][:pve_user_name],
        :realm=>Chef::Config[:knife][:pve_user_realm],
        :password=>Chef::Config[:knife][:pve_user_password] do |response, request, result, &block| 
        if response.code == 200 then
          data = JSON.parse(response.body)
          ticket = data['data']['ticket']
          csrf_prevention_token = data['data']['CSRFPreventionToken']
          if !ticket.nil? then
            token = 'PVEAuthCookie=' + ticket.gsub!(/:/,'%3A').gsub!(/=/,'%3D')
          end
        end
      end
      {:CSRFPreventionToken => csrf_prevention_token, :cookie => token} 
    end
    
  end
  
  
  
end
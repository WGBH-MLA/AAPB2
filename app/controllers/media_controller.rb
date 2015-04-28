require_relative '../../lib/access_control'

class MediaController < ApplicationController
  include Blacklight::Catalog
  
  CREDENTIALS_PATH = Rails.root + 'config/ci.yml'

  def show
    if AccessControl.authorized_ip?(request.remote_ip) && 
        URI.parse(request.referer).host =~ /^(.+\.)?americanarchive\.org$/      
      ci = CiCore.new(credentials_path: CREDENTIALS_PATH)
      # OAuth credentials expire: otherwise it would make sense to cache this instance.
      
      _response, document = fetch(params['id'])
      xml = document.instance_variable_get('@_source')['xml']
      pbcore = PBCore.new(xml)
      
      redirect_to ci.download(pbcore.ci_id)
    else
      render nothing: true, status: :unauthorized
    end
  end
end

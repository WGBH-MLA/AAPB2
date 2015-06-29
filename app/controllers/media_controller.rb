require_relative '../../lib/access_control'

class MediaController < ApplicationController
  include Blacklight::Catalog

  def show
    if AccessControl.authorized_ip?(request.remote_ip) 
        # TODO: Add referer check when reading rooms are up.
        # || ( AccessControl.reading_room?
        #      && URI.parse(request.referer).host =~ /^(.+\.)?americanarchive\.org$/ )
      _response, document = fetch(params['id'])
      xml = document.instance_variable_get('@_source')['xml']
      pbcore = PBCore.new(xml)

      ci = SonyCiBasic.new(credentials_path: Rails.root + 'config/ci.yml')
      # OAuth credentials expire: otherwise it would make sense to cache this instance.
      redirect_to ci.download(pbcore.ci_id)
    else
      render nothing: true, status: :unauthorized
    end
  end
end

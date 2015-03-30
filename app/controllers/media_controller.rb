require_relative '../../lib/access_control'

class MediaController < ApplicationController
  include Blacklight::Catalog

  def show
    _response, document = fetch(params['id'])
    xml = document.instance_variable_get('@_source')['xml']
    pbcore = PBCore.new(xml)

    ci = CiCore.new(credentials_path: File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml')
    # OAuth credentials expire: otherwise it would make sense to cache this instance.
    if AccessControl.authorized_ip?(request.remote_ip)
      redirect_to ci.download(pbcore.ci_id)
    else
      render nothing: true, status: :unauthorized
    end
  end
end

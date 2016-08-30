class MediaController < ApplicationController
  include Blacklight::Catalog

  def show
    _response, document = fetch(params['id'])
    xml = document['xml']
    pbcore = PBCore.new(xml)

    # if can?(:play, pbcore) && (current_user.aapb_referer? || current_user.embed?)
    if can?(:access_media_url, pbcore)
      ci = SonyCiBasic.new(credentials_path: Rails.root + 'config/ci.yml')
      # OAuth credentials expire: otherwise it would make sense to cache this instance.
      redirect_to ci.download(pbcore.ci_ids[(params['part'] || 1).to_i - 1])
    else
      render nothing: true, status: :unauthorized
    end
  end
end

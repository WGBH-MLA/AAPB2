class MediaController < ApplicationController
  include Blacklight::Catalog

  def show
    _response, document = fetch(params['id'])
    xml = document['xml']
    pbcore = PBCore.new(xml)

    if can?(:play, pbcore) && (current_user.aapb_referer? || current_user.embed?)
      ci = SonyCiBasic.new(credentials_path: Rails.root + 'config/ci.yml')
      # OAuth credentials expire: otherwise it would make sense to cache this instance.
      ci_id = pbcore.ci_ids[(params['part'].to_i || 1) - 1]
      if can?(:play, ci_id)
        redirect_to ci.download(pbcore.ci_ids[(params['part'].to_i || 1) - 1])
        return
      end
    end
    render nothing: true, status: :unauthorized
  end
end

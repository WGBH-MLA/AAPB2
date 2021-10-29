require 'sony_ci_api'

class MediaController < ApplicationController
  include Blacklight::Catalog
  include BlacklightGUIDFetcher

  def show
    # From BlacklightGUIDFetcher
    _response, document = fetch_from_blacklight(params[:id])

    xml = document['xml']
    pbcore = PBCorePresenter.new(xml)

    # if can?(:play, pbcore) && (current_user.aapb_referer? || current_user.embed?)
    if can?(:access_media_url, pbcore)
      @client = SonyCiApi::Client.new(Rails.root + 'config/ci.yml')
      # OAuth credentials expire: otherwise it would make sense to cache this instance.
      ci_id = pbcore.ci_ids[(params['part'] || 1).to_i - 1]
      redirect_to @client.asset_stream_hls_url(ci_id)
    else
      render nothing: true, status: :unauthorized
    end
  end
end

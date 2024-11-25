require 'sony_ci_api'

class MediaController < ApplicationController
  include Blacklight::Catalog
  include BlacklightGUIDFetcher

  def show
    if can?(:access_media_url, pbcore)
      # TODO wrap in conditional after testing
      allow_cors!
      redirect_to media_url
    else
      render nothing: true, status: :unauthorized
    end
  end

  private

  def media_url
    @media_url ||= begin
      if pbcore.video?
        sony_ci.asset_stream_url(ci_id, type: "hls")
      elsif pbcore.audio?
        sony_ci.asset_download(ci_id)['location']
      end
    end
  end

  def ci_id
    @ci_id ||= pbcore.ci_ids[part - 1]
  end

  def part
    @part ||= (params['part'] || 1).to_i
  end

  def pbcore
    @pbcore ||= PBCorePresenter.new(solr_doc['xml'])
  end

  def solr_doc
    @solr_doc ||= begin
      _resp, doc = fetch_from_solr(params['id'])
      doc
    end
  end

  def sony_ci
    @sony_ci ||= SonyCiApi::Client.new(Rails.root + 'config/ci.yml')
  end

  def allow_cors!
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end
end

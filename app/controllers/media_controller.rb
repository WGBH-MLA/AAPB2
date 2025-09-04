require 'sony_ci_api'

class MediaController < ApplicationController
  include Blacklight::Catalog
  include BlacklightGUIDFetcher

  before_action do
    # Return a 404 the object is not in Solr
    render nothing: true, status: :not_found unless solr_doc
  end

  def show
    if can?(:access_media_url, pbcore)
      redirect_to media_url
    else
      render nothing: true, status: :unauthorized
    end
  end

  def download
    if can?(:access_media_url, pbcore)
      redirect_to media_url(for_download: true)
    else
      render nothing: true, status: :unauthorized
    end
  rescue SonyCiApi::HttpError => http_error
    render text: http_error.message, status: http_error.status
  end

  private

  def media_url(for_download: false)
    if pbcore.audio? || for_download
      sony_ci.asset_download(ci_id)['location']
    elsif pbcore.video?
      sony_ci.asset_stream_url(ci_id, type: "hls")
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
end

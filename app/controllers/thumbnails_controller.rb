# This exists just so that shorter, stable image src urls can be used in markdown.
# It should not be used from inside the code when we have the PBCore object itself.
class ThumbnailsController < ApplicationController
  include Blacklight::Catalog
  include BlacklightGUIDFetcher

  # We don't want to hit solr and parse xml and go through the logic again every time.
  def show
    id = params['id']
    img_src = Rails.cache.fetch("thumb/#{id}") do
      _response, document = fetch_from_solr(id)
      xml = document['xml']
      PBCorePresenter.new(xml).img_src
    end
    redirect_to img_src
  end
end

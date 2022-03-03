class CaptionsController < ApplicationController
  include Blacklight::Catalog
  include BlacklightGUIDFetcher

  def show
    # From BlacklightGUIDFetcher
    # Need to use for proper routing
    @response, @document = fetch_from_solr(params['id'])

    # we have to rescue from this in fetch_from_solr to run through all guid permutations, so throw it here if we didnt find anything
    raise Blacklight::Exceptions::RecordNotFound unless @document

    pbcore = PBCorePresenter.new(@document['xml'])
    caption_file = CaptionFile.new(pbcore.id)

    respond_to do |format|
      format.html do
        @captions_html = caption_file.html
        render
      end
      format.vtt do
        render text: caption_file.vtt
      end
      format.srt do
        render text: caption_file.srt
      end
    end
  end
end

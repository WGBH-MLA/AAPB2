class CaptionsController < ApplicationController
  include Blacklight::Catalog
  # include BlacklightGUIDFetcher

  def show
    caption_file = CaptionFile.retrieve_captions(params['id'])
    raise Blacklight::Exceptions::RecordNotFound unless caption_file.file_present?

    respond_to do |format|
      # we only use .vtt here, but technically could be resource for someone external to AAPB
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

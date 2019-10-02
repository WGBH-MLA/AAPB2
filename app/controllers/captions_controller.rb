class CaptionsController < ApplicationController
  include Blacklight::Catalog

  def show
    @response, @document = fetch(params['id'])
    pbcore = PBCorePresenter.new(@document['xml'])
    caption_file = CaptionFile.new(pbcore.captions_src)

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

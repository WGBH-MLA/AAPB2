class CaptionsController < ApplicationController

  def show
    caption_file = CaptionFile.new(params[:id])

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

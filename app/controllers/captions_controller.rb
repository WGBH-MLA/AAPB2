class CaptionsController < ApplicationController
  def show
    source_filetype = params[:ext]
    caption_file = CaptionFile.new(params[:id], source_filetype)

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

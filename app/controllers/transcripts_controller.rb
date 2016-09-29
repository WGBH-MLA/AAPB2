class TranscriptsController < ApplicationController
  layout 'transcript'
  caches_page :show

  def show
    caption_file = CaptionFile.new(params[:id])

    respond_to do |format|
      format.html do
        @transcript_html = caption_file.html
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

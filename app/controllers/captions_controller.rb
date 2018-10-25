class CaptionsController < ApplicationController
  def show
    # TODO: doing this sourcefile param method to preserve the semantics of this controller (say .html, get html back), but check if this is useful and change ext to source if we really just want vtt out of this
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

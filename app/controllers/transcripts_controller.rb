class TranscriptsController < ApplicationController
  layout 'transcript'
  caches_page :show

  def show
    transcript_file = TranscriptFile.new(params[:id])

    respond_to do |format|
      format.html do
        @transcript_html = transcript_file.html
        render
      end
      format.json do
        puts "Woooooo!"
      end
    end
  end
end

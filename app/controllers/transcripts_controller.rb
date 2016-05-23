class TranscriptsController < ApplicationController
  layout 'transcript'

  caches_page :show
  def show
    curl = Curl::Easy.http_get(PBCore.srt_url(params[:id]))
    curl.perform

    respond_to do |format|
      format.html do
        @transcript_html = Transcripter.from_srt(curl.body_str)
        render
      end
      format.srt do # TODO: make the live code reference this, instead of going through PBCore?
        render text: curl.body_str
      end
    end
  end
end

class TranscriptsController < ApplicationController
  layout 'transcript'

  caches_page :show
  def show
    curl = Curl::Easy.http_get(PBCore.srt_url(params[:id]))
    # Necessary? curl.headers['Referer'] = 'http://americanarchive.org/'
    curl.perform

    respond_to do |format|
      format.html do
        @transcript_html = Transcripter.from_srt(curl.body_str)
        render
      end
    end
  end
end

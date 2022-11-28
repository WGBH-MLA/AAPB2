class TranscriptsController < ApplicationController
  include Blacklight::Catalog

  layout 'transcript'
  caches_page :show

  def show
    @response, @document = fetch(params['id'])
    xml = @document['xml']
    pbcore = PBCorePresenter.new(xml)

    if params[:start] && params[:end]
      start_time = params[:start]
      end_time = params[:end]
    end
    
    @transcript_file = TranscriptFile.new(params['id'], pbcore.transcript_src, start_time, end_time)

    return [404, "Transcript does not exist"] unless @transcript_file.file_present?
    respond_to do |format|
      format.html do
        @transcript_html = @transcript_file.html
        render
      end
    end
  end
end

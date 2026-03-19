class TranscriptsController < ApplicationController
  include Blacklight::Catalog

  layout 'transcript'
  caches_page :show

  def show
    @response, @document = fetch(params['id'])
    xml = @document['xml']
    pbcore = PBCorePresenter.new(xml)

    # Enforce access_transcript ability
    unless can?(:access_transcript, pbcore)
      return render plain: "Transcript not available", status: :forbidden
    end

    # Optional start/end parameters
    start_time = params[:start]
    end_time = params[:end]

    @transcript_file = TranscriptFile.new(params['id'], pbcore.transcript_src, start_time, end_time)

    # Return 404 if transcript file does not exist
    unless @transcript_file.file_present?
      return render plain: "Transcript does not exist", status: :not_found
    end

    respond_to do |format|
      format.html do
        @transcript_html = @transcript_file.html
        render
      end
    end
  end
end

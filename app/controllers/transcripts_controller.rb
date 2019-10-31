class TranscriptsController < ApplicationController
  include Blacklight::Catalog

  layout 'transcript'
  caches_page :show

  def show
    @response, @document = fetch(params['id'])

    xml = @document['xml']
    pbcore = PBCorePresenter.new(xml)
    @transcript_file = TranscriptFile.new(pbcore.transcript_src)

    respond_to do |format|
      format.html do
        @transcript_html = @transcript_file.html
        render
      end
    end
  end
end

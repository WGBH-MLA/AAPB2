class PrimarySourceSetsController < OverrideController
  include ApplicationHelper
  include IdHelper

  def index
    @all_resource_sets = PrimarySourceSet.all_resource_sets
    @page_title = 'Multimedia Primary Source Discussion Sets'
  end

  def show
    @primary_source_set = PrimarySourceSet.find_by_path(params[:path])

    raise ActionController::RoutingError.new('Not Found') unless @primary_source_set
    @page_title = @primary_source_set.title

    if @primary_source_set.guid
      doc = find_doc(@primary_source_set.guid)
      raise "Record not found with guid #{@primary_source_set.guid}" unless doc

      @pbcore = PBCorePresenter.new(doc['xml'])

      @transcript_html = @pbcore.transcript_html(@primary_source_set.clip_start, @primary_source_set.clip_end)

      @captions = CaptionFile.retrieve_captions(@pbcore.id)

      @transcript_search_term = params['term']
      # how shown are we talkin here?
      @transcript_open = @pbcore.correct_transcript? ? true : false
    end

    params[:path] = nil
  end
end

private

def find_doc(guid)
  doc = nil
  @solr = Solr.instance.connect

  id_styles(guid).each do |g|
    resp = @solr.get('select', params: { q: "id:#{g}", fl: 'xml' })
    doc = resp['response']['docs'].first if resp['response'] && resp['response']['docs']
    break if doc
  end

  doc
end

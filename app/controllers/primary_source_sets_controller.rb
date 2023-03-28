class PrimarySourceSetsController < OverrideController
  include ApplicationHelper

  def index
    @all_resource_sets = PrimarySourceSet.all_resource_sets
    @page_title = 'Multimedia Primary Source Discussion Sets'
  end

  def show
    @primary_source_set = PrimarySourceSet.find_by_path(params[:path])

    raise ActionController::RoutingError.new('Not Found') unless @primary_source_set
    @page_title = @primary_source_set.title

    if @primary_source_set.guid
      @solr = Solr.instance.connect
      resp = @solr.get('select', params: { q: "id:#{@primary_source_set.guid}", fl: 'xml' })
      doc = resp['response']['docs'].first if resp['response'] && resp['response']['docs']
      redirect_to '/' and return unless doc
      @pbcore = PBCorePresenter.new(doc['xml'])

      @captions = CaptionFile.retrieve_captions(@pbcore.id)

      @transcript_search_term = params['term']
      # how shown are we talkin here?
      @transcript_open = @pbcore.correct_transcript? ? true : false
    end

    params[:path] = nil
  end
end

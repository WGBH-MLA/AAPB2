
class PrimarySourceSetsController < OverrideController
  include Blacklight::Catalog
  include ApplicationHelper
  include BlacklightGUIDFetcher

  def index
    @all_resource_sets = PrimarySourceSet.all_resource_sets
    @page_title = 'Multimedia Primary Source Discussion Sets'
  end

  def show
    @primary_source_set = PrimarySourceSet.find_by_path(params[:path])
    # TODO put back
    # @other_sets = PrimarySourceSet.all_resource_sets.reject {|set| set.path == @primary_source_set.path }
    @other_sets = PrimarySourceSet.all_resource_sets

    raise ActionController::RoutingError.new('Not Found') unless @primary_source_set
    @page_title = @primary_source_set.title

    if @primary_source_set.guid
      @response, @document = fetch_from_solr(@primary_source_set.guid)
      redirect_to '/' and return unless @document
      @pbcore = PBCorePresenter.new(@document['xml'])

      @captions = CaptionFile.retrieve_captions(@pbcore.id)

      @transcript_search_term = params['term']
      # how shown are we talkin here?
      @transcript_open = @pbcore.correct_transcript? ? true : false
    end

    params[:path] = nil
  end
end

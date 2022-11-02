
class EducatorResourcesController < OverrideController
  include Blacklight::Catalog
  include ApplicationHelper
  include BlacklightGUIDFetcher

  def index
    @all_resource_sets = EducatorResource.all_resource_sets
    @page_title = 'Educator Resources'
  end

  def show
    @educator_resource = EducatorResource.find_by_path(params[:path])
    raise ActionController::RoutingError.new('Not Found') unless @educator_resource
    @page_title = @educator_resource.title

    if @educator_resource.guid
      @response, @document = fetch_from_solr(@educator_resource.guid)
      @pbcore = PBCorePresenter.new(@document['xml'])

      @captions = CaptionFile.retrieve_captions(@pbcore.id)

      @transcript_search_term = params['term']
      # how shown are we talkin here?
      @transcript_open = @pbcore.correct_transcript? ? true : false
    end

    params[:path] = nil
  end
end

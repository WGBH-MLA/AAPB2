require_relative '../models/exhibit'

class EducatorResourcesController < OverrideController
  def index
    @all_resource_sets = EducatorResource.all_resource_sets
    @page_title = 'Educator Resources'
  end

  def show
    @educator_resource = EducatorResource.find_by_path(params[:path])
    raise ActionController::RoutingError.new('Not Found') unless @educator_resource
    @page_title = @educator_resource.title
    params[:path] = nil
  end
end

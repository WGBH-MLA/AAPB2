require_relative '../models/special_collection'

class SpecialCollectionsController < OverrideController
  def index
    @top_level_special_collections = SpecialCollection.all_top_level
    @page_title = 'Special Collections'
  end

  def show
    @special_collection = SpecialCollection.find_by_path(params[:path])
    raise ActionController::RoutingError.new('Not Found') unless @special_collection
    @page_title = @special_collection.title
    params[:path] = nil
  end
end

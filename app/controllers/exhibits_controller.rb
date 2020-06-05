require_relative '../models/exhibit'

class ExhibitsController < OverrideController
  def index
    @top_level_exhibits = Exhibit.all_top_level
    @page_title = 'Exhibits'
  end

  def show
    @exhibit = Exhibit.find_by_path(params[:path])
    raise ActionController::RoutingError.new('Not Found') unless @exhibit
    @page_title = @exhibit.top_title
    params[:path] = nil
  end
end

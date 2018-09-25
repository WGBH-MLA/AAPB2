require_relative '../models/exhibit'

class ExhibitsController < OverrideController
  def index
    @top_level_exhibits = Exhibit.all_top_level
    @page_title = 'Exhibits'
  end

  def show
    require('pry');binding.pry
    @exhibit = Exhibit.find_by_path(params[:path])
    @page_title = @exhibit.title
    params[:path] = nil
  end
end

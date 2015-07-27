require_relative '../models/exhibit'

class ExhibitsController < OverrideController
  def index
    @exhibits = Exhibit.all
    @page_title = 'Exhibits'
  end
  
  def show
    @exhibit = Exhibit.find_by_path(params[:path])
    @page_title = @exhibit.title
    params[:path] = nil 
  end
end
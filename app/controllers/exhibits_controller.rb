require_relative '../models/exhibit'

class ExhibitsController < OverrideController
  # TODO: Do we need an index?
#  def index
#    @orgs = Exhibit.all
#    render 'index'
#  end

  def set_view_fields(path)
    @exhibit = Exhibit.find_by_path(Exhibit.path_from_file_path(path))
    @page_title = @exhibit.name
  end
end
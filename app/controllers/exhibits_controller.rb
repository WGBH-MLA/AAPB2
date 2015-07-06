require_relative '../models/exhibit'

class ExhibitsController < OverrideController
  # TODO: Do we need an index?
#  def index
#    @orgs = Exhibit.all
#    render 'index'
#  end

  def set_view_fields(path)
    @exhibit = Exhibit.find_by_path(File.basename(path, '.md'))
    @page_title = @exhibit.name
  end
end
require_relative '../models/exhibit'

class ExhibitsController < OverrideController
  def index
    story_map_exhibit = LinkExhibit.new(title: "Witnessing New Mexico: The New Mexico Public Media Digitization Project", external_url: "https://storymaps.arcgis.com/stories/39eecf9cbc484f36802799c4046ebd61", thumbnail_url: "https://s3.amazonaws.com/americanarchive.org/exhibits/nm_storymap_cover.png", new_tab: true)
    @top_level_exhibits = Exhibit.all_top_level + [story_map_exhibit]
    @page_title = 'Exhibits'
  end

  def show
    @exhibit = Exhibit.find_by_path(params[:path])
    raise ActionController::RoutingError.new('Not Found') unless @exhibit
    @page_title = @exhibit.top_title
    params[:path] = nil
  end
end

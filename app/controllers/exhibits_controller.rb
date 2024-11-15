require_relative '../models/exhibit'

class ExhibitsController < OverrideController
  def index
    witness_nm_promo = LinkExhibit.new(title: "Witnessing New Mexico: The New Mexico Public Media Digitization Project", external_url: "/witnessing-nm", thumbnail_url: "https://s3.amazonaws.com/americanarchive.org/exhibits/nm_storymap_cover.png", new_tab: false)
    @top_level_exhibits = Exhibit.all_top_level + [witness_nm_promo]
    @page_title = 'Exhibits'
  end

  def show
    @exhibit = Exhibit.find_by_path(params[:path])
    raise ActionController::RoutingError.new('Not Found') unless @exhibit
    @page_title = @exhibit.top_title
    params[:path] = nil
  end
end

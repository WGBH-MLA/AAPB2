require_relative '../models/exhibit'
Rails.backtrace_cleaner.remove_silencers!

class ExhibitsController < OverrideController
  def index
    @top_level_exhibits = Exhibit.all_top_level
    @page_title = 'Exhibits'
  end

  def show
    @exhibit = Exhibit.new(params[:path])
    @page_title = @exhibit.title
    params[:path] = nil
  end
end

class ExhibitsController < ApplicationController
  # TODO: Do we need an index?
#  def index
#    @orgs = Exhibit.all
#    render 'index'
#  end

  def show
    @exhibit = Exhibit.find_by_slug(params[:id])
    render 'show'
  end
end
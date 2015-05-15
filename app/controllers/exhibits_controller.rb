class ExhibitsController < ApplicationController
  # TODO: Do we need an index?
#  def index
#    @orgs = Exhibit.all
#    render 'index'
#  end

  def show
    @all = Exhibit.all
    @exhibit = Exhibit.find_by_slug(params[:id])
    @page_title = @exhibit.name
    params[:path] = nil # search widget grabs ALL parameters.
    render 'show'
  end
end
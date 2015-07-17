class OrganizationsController < ApplicationController
  def index
    @orgs = Organization.all
    @page_title = 'Participating Organizations'
    render 'index'
  end

  def show
    @org = Organization.find_by_id(params[:id])
    @page_title = @org.short_name
    render 'show'
  end
end

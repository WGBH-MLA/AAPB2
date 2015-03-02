class OrganizationsController < ApplicationController
  
  def index
    @orgs = Organization.all
    render 'index'
  end
  
  def show
    @org = Organization.find_by_id(params[:id])
    render 'show'
  end
  
end

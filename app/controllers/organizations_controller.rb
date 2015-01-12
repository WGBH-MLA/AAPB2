class OrganizationsController < ApplicationController
  
  def index
    @orgs = Organization.all
    render 'index'
  end
  
  def show
    @org = Organization.find(params[:id])
    render 'show'
  end
  
end
class OrganizationsController < ApplicationController
  def index
    @states = State.all.sort_by(&:name)
    @page_title = 'Participating Organizations'
  end

  def show
    @org = Organization.find_by_id(params[:id])
    raise ActionController::RoutingError.new('Organization Not Found') unless @org
    @page_title = @org.short_name
  end
end

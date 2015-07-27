require_relative '../../lib/markdowner'

class OverrideController < ApplicationController
  def show
    @override = Override.find_by_path(params[:path])
  rescue IndexError 
    fail ActionController::RoutingError.new('404')
  end
end
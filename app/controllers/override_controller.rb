require_relative '../../lib/markdowner'

class OverrideController < ApplicationController
  def show

  	if params[:path]
    	@override = Override.find_by_path(params[:path])
    	@page_title = @override.title
    	params[:path] = nil # search widget grabs ALL parameters.
    end

  rescue IndexError
    raise ActionController::RoutingError.new('404')
  end
end

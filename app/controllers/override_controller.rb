require_relative '../../lib/markdowner'

class OverrideController < ApplicationController
  include PublicCache

  def show
    @override = Override.find_by_path(params[:path])
    raise ActionController::RoutingError.new('Not Found') unless @override
    @page_title = @override.title
    params[:path] = nil # search widget grabs ALL parameters.
  end
end

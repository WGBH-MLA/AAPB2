require_relative '../../lib/markdowner'

class PlainOverrideController < ApplicationController
  layout 'plain'

  def show
    @plain_override = PlainOverride.find_by_path(params[:path])
    @page_title = @plain_override.title
    params[:path] = nil # search widget grabs ALL parameters.
  rescue IndexError
    raise ActionController::RoutingError.new('404')
  end
end

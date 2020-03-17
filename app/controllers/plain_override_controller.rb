require_relative '../../lib/markdowner'

class PlainOverrideController < ApplicationController
  layout 'plain'

  def show
    @plain_override = PlainOverride.find_by_path(params[:path])
    raise ActionController::RoutingError.new('Not Found') unless @plain_override
    @page_title = @plain_override.title
    params[:path] = nil # search widget grabs ALL parameters.
  end
end

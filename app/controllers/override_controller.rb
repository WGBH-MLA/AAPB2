require_relative '../../lib/markdowner'

class OverrideController < ApplicationController
  def show
    # whitelist real paths to avoid *mischief*    
    return 404 unless ['/about-the-american-archive','/contact-us','/donate','/faq','/on-location','/resources','/search'].include?(request.path)
    path = request.path.delete('/')

    @override = Override.find_by_path(path)
    @page_title = @override.title
    params[:path] = nil # search widget grabs ALL parameters.

  rescue IndexError
    raise ActionController::RoutingError.new('404')
  end
end

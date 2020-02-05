require_relative '../../lib/markdowner'

class OverrideController < ApplicationController
  def show
    # whitelist real paths to avoid *mischief*    
    return 404 unless ['/about-the-american-archive','/contact-us','/donate','/faq','/on-location','/resources','/search','/help','/legal'].any? {|route| request.path.start_with?(route)}

    path = request.path
    # cmless doesnt take the leading slash for its path
    path[0] = ''

    @override = Override.find_by_path(path)
    @page_title = @override.title
    params[:path] = nil # search widget grabs ALL parameters.

  rescue IndexError
    raise ActionController::RoutingError.new('404')
  end
end

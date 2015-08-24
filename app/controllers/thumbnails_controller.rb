# This exists just so that shorter, stable image src urls can be used in markdown.
# It should not be used from inside the code when we have the PBCore object itself.
class ThumbnailsController < ApplicationController
  include Blacklight::Catalog

  CACHE = {}
  
  def show
    id = params['id']
    CACHE[id] ||= begin
      _response, document = fetch(id)
      xml = document.instance_variable_get('@_source')['xml']
      PBCore.new(xml).img_src
    end
    redirect_to CACHE[id]
  end
end

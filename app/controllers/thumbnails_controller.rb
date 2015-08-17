# This exists just so that shorter, stable image src urls can be used in markdown.
# It should not be used from inside the code when we have the PBCore object itself.
class ThumbnailsController < ApplicationController
  include Blacklight::Catalog

  def show
    _response, document = fetch(params['id'])
    xml = document.instance_variable_get('@_source')['xml']
    pbcore = PBCore.new(xml)
    redirect_to pbcore.img_src
  end
end

# NOTE: This is only provided for backwards compatibility with the AMS.
# If the AMS goes away, please delete this controller.

class AmsController < ApplicationController
  include Blacklight::Catalog

  def show
    params['id'].sub!('cpb-aacip-', 'cpb-aacip_')
    _response, document = fetch(params['id'])
    pb_core = PBCore.new(document.instance_variable_get('@_source')['xml'])
    if pb_core.ci_id
      format = 'mp3' # TODO: others?
      # We could conceivably hit the Ci API here,
      # but I don't think that would be a good idea.
      url = "http://americanarchive.org/media/#{params['id']}"
      render text: "<data><format>#{format}</format><mediaurl>#{url}</mediaurl></data>"
    else
      render status: 404, text: '<error>No media file</error>'
    end
  rescue Blacklight::Exceptions::RecordNotFound
    render status: 404, text: '<error>Bad ID</error>'
  end
end

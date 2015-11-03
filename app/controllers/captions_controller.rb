class CaptionsController < ApplicationController
  include Blacklight::Catalog

  def show
# For debugging:
#    render text: <<END
# 1
# 00:00:01,000 --> 00:00:03,000
# CAPTIONS CONTROLLER!!!

    _response, document = fetch(params['id'])
    captions = document['captions']
    if captions
      render text: captions
    else
      render nothing: true, status: :unauthorized
    end
  end
end

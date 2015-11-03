require_relative '../../lib/geo_i_p_country'
require_relative '../../lib/aapb'

class EmbedController < CatalogController
  layout 'embed'
  
  def terms_target
    '/embed_terms/'
  end
  
  def show
    super
    response.headers.delete('X-Frame-Options')
  end
end

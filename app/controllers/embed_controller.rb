require_relative '../../lib/aapb'

class EmbedController < CatalogController
  layout 'embed'

  def terms_target
    '/embed_terms/'
  end

  def show
    @is_clipped = request.url =~ /start=\d{1,10}\.\d{2}&end=\d{1,10}\.\d{2}/
    super
    response.headers.delete('X-Frame-Options')
  end
end

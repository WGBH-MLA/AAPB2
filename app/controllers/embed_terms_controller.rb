class EmbedTermsController < TermsController
  layout 'embed'

  def target
    '/embed/'
  end

  def show
    super
    response.headers.delete('X-Frame-Options')
  end
end

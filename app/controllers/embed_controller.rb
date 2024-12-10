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

  def lite
    @response, @document = fetch_from_solr(params['id'])
    raise Blacklight::Exceptions::RecordNotFound unless @document
    xml = @document['xml']
    @pbcore = PBCorePresenter.new(xml)

    response.headers.delete('X-Frame-Options')
    if can? :play_embedded, @pbcore
      # can? play because we're inside this block
      if @pbcore.proxy_start_time && params["proxy_start_time"].nil? && !media_start_time?(params)
        params["proxy_start_time"] = @pbcore.proxy_start_time
      end

      render 'lite', layout: 'lite_embed'
    else
      head :unauthorized
    end
  end

  def openvault
    @response, @document = fetch_from_solr(params['id'])
    raise Blacklight::Exceptions::RecordNotFound unless @document
    xml = @document['xml']
    @pbcore = PBCorePresenter.new(xml)

    response.headers.delete('X-Frame-Options')
    response.headers['Content-Security-Policy'] = 'frame-ancestors https://ov.wgbh-mla.org http://localhost:4000 http://localhost:3000;'

    if can? :play, @pbcore
      # can? play because we're inside this block
      if @pbcore.proxy_start_time && params["proxy_start_time"].nil? && !media_start_time?(params)
        params["proxy_start_time"] = @pbcore.proxy_start_time
      end
    else
      head :unauthorized
    end
  end

  def video
    @response, @document = fetch_from_solr(params['id'])
    raise Blacklight::Exceptions::RecordNotFound unless @document
    xml = @document['xml']
    @pbcore = PBCorePresenter.new(xml)

    response.headers.delete('X-Frame-Options')

    if can? :play, @pbcore
      # can? play because we're inside this block
      if @pbcore.proxy_start_time && params["proxy_start_time"].nil? && !media_start_time?(params)
        params["proxy_start_time"] = @pbcore.proxy_start_time
      end
    else
      head :unauthorized
    end
  end
end

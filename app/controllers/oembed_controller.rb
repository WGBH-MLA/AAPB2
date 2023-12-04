require_relative '../../lib/aapb'

class OembedController < CatalogController
  def show
    render json: {
        "title": pbcore_presenter.title,
        "type": "video/mp4",
        "width": "1640",
        "height": "1480",
        "src": "https://americanarchive.org/embed/#{pbcore_presenter.id}",
    }
  end


  private

  def pbcore_presenter
    @pbcore_presenter ||= PBCorePresenter.new(solr_doc['xml'])
  end

  def solr_doc
    @solr_doc ||= begin
      _resp, doc = fetch_from_solr(id_from_url_param)
      raise Blacklight::Exceptions::RecordNotFound unless doc
      doc
    end
  end

  def id_from_url_param
    @id_from_url_param ||= begin
        uri = URI.parse(params['url'])
        path_parts = uri.path.split('/')
        path_parts.detect {|path_part| path_part =~ /^cpb\-aacip/}
    end
  end
end

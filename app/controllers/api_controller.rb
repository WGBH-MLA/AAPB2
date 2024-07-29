require_relative '../../lib/solr'
require 'nokogiri'

class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  # TODO: There is nothing we have that is worth a CSRF, but CORS is a better way to do this.

  http_basic_authenticate_with name: ENV['API_USER'], password: ENV['API_PASSWORD'], only: [:transcript]

  def index
    @solr = Solr.instance.connect
    callback = params.delete('callback') || 'callback'
    rows = [params.delete('rows').to_i, 100].min
    data = begin
      @solr.get('select', params: params.except(:action, :format, :controller).merge(rows: rows))
    rescue => e
      # RSolr dictates that responses be ruby data structures,
      # but the eval still scares me.
      eval(e.response[:body])
    end
    json = JSON.pretty_generate(data)
    respond_to do |format|
      format.js do
        render text: "#{callback}(#{json});",
               status: data['error'] ? 500 : 200
      end
      format.json do
        render text: json,
               status: data['error'] ? 500 : 200
      end
      format.xml do
        render text: data.to_xml,
               status: data['error'] ? 500 : 200
      end
    end
  end

  def show
    @solr = Solr.instance.connect
    data = @solr.get('select', params: { q: "id:#{params[:id]}", fl: 'xml' })

    return render_not_found(params[:id]) unless data['response']['docs'] && data['response']['docs'][0]
    xml = data['response']['docs'][0]['xml']

    respond_to do |format|
      format.xml do
        render text: xml
      end

      format.json do
        # escape double quotes (because they may appear in node values)
        xml = xml.gsub(%(\"), %(\\\"))

        json = pbcore_xml_to_json_xsl_doc.transform(Nokogiri::XML(xml))
        render json: JSON.pretty_generate(
          JSON.parse(json)
        )
      end
    end
  end

  def transcript
    @solr = Solr.instance.connect
    data = @solr.get('select', params: { q: "id:#{params[:id]}", fl: 'xml' })
    xml = data['response']['docs'][0]['xml']
    @pbcore = PBCorePresenter.new(xml)
    content = @pbcore.transcript_content

    if can?(:api_access_transcript, @pbcore) && !content.nil?
      render json: content, status: :ok
    else
      render_no_transcript_content
    end
  end

  def render_no_transcript_content
    render json: { status: '404 Not Found', code: '404', message: 'This transcript is not currently available' }, status: :not_found
  end

  def render_not_found(guid)
    render json: { status: '404 Not Found', code: '404', message: "Record #{guid} not found" }, status: :not_found
  end

  private

  def pbcore_xml_to_json_xsl_doc
    Rails.cache.fetch("pbcore_xml_to_json_xsl_doc") do
      return Nokogiri::XSLT(File.read('./lib/pbcore_xml_to_json.xsl'))
    end
  end
end

require_relative '../../lib/solr'
require 'nokogiri'

class ApiController < ApplicationController
  include PBCore::ToJSON

  skip_before_action :verify_authenticity_token
  # TODO: There is nothing we have that is worth a CSRF, but CORS is a better way to do this.

  http_basic_authenticate_with name: ENV['API_USER'], password: ENV['API_PASSWORD'], only: [:transcript]

  def index
    @solr = Solr.instance.connect
    callback = params.delete('callback') || 'callback'

    rows = [params.delete('rows').to_i, 100].min
    # rows = params.delete('rows')

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
    # Replace the delimiter at the end fo the AAPB ID prefix with a single character wildcard
    # to return any docs that are indexed with old-style ID's, having a slash, or sometimes an underscore
    # instead of a dash. Eventually, all records should have new-style IDs with the dashes. Until then, this.
    id = params[:id].sub(/cpb-aacip./, "cpb-aacip?")
    data = @solr.get('select', params: { q: "id:#{id}", fl: 'xml' })

    return render_not_found(params[:id]) unless data['response']['docs'] && data['response']['docs'][0]
    xml = data['response']['docs'][0]['xml']

    respond_to do |format|
      format.xml do
        render text: xml
      end

      format.json do
        # PBCore::ToJSON method
        output = pbxml_to_json(xml)
        render json: output
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

  def arrayify_node(node)
    # if truthy and not already array, wrap in array
    if node
      if node.is_a?(Array)
        node
      else
        [node]
      end
    end
  end

  private

  def pbcore_xml_to_json_xsl_doc
    Rails.cache.fetch("pbcore_xml_to_json_xsl_doc") do
      return Nokogiri::XSLT(File.read('./lib/pbcore_xml_to_json.xsl'))
    end
  end
end

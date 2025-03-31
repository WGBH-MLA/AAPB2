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
        # escape double quotes (because they may appear in node values)
        xml = xml.gsub(%(\"), %(\\\"))

        json = pbcore_xml_to_json_xsl_doc.transform(Nokogiri::XML(xml))
        data = JSON.parse(json)
        raise "No Desc Doc TOO BAD" unless data && data["pbcoreDescriptionDocument"]

        # top multis
        data["pbcoreDescriptionDocument"]["pbcoreAssetType"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreAssetType"])
        data["pbcoreDescriptionDocument"]["pbcoreAssetDate"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreAssetDate"])
        data["pbcoreDescriptionDocument"]["pbcoreIdentifier"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreIdentifier"])
        data["pbcoreDescriptionDocument"]["pbcoreTitle"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreTitle"])
        data["pbcoreDescriptionDocument"]["pbcoreSubject"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreSubject"])
        data["pbcoreDescriptionDocument"]["pbcoreDescription"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreDescription"])
        data["pbcoreDescriptionDocument"]["pbcoreGenre"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreGenre"])
        data["pbcoreDescriptionDocument"]["pbcoreAudienceLevel"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreAudienceLevel"])
        data["pbcoreDescriptionDocument"]["pbcoreAudienceRating"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreAudienceRating"])
        data["pbcoreDescriptionDocument"]["pbcoreAnnotation"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreAnnotation"])
        
        # subelements but not multi
        data["pbcoreDescriptionDocument"]["pbcoreRelation"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreRelation"])
        data["pbcoreDescriptionDocument"]["pbcoreCoverage"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreCoverage"])
        
        # nested multis
        data["pbcoreDescriptionDocument"]["pbcoreCreator"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreCreator"])
        if data["pbcoreDescriptionDocument"]["pbcoreCreator"] && data["pbcoreDescriptionDocument"]["pbcoreCreator"].count > 0
          data["pbcoreDescriptionDocument"]["pbcoreCreator"].each_with_index do |creator,index|
            data["pbcoreDescriptionDocument"]["pbcoreCreator"][index]["creatorRole"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreCreator"][index]["creatorRole"])
          end
        end

        data["pbcoreDescriptionDocument"]["pbcoreContributor"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreContributor"])
        if data["pbcoreDescriptionDocument"]["pbcoreContributor"] && data["pbcoreDescriptionDocument"]["pbcoreContributor"].count > 0
          data["pbcoreDescriptionDocument"]["pbcoreContributor"].each_with_index do |contributor,index|
            data["pbcoreDescriptionDocument"]["pbcoreContributor"][index]["contributorRole"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreContributor"][index]["contributorRole"])
          end
        end
        data["pbcoreDescriptionDocument"]["pbcorePublisher"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcorePublisher"])
        if data["pbcoreDescriptionDocument"]["pbcorePublisher"] && data["pbcoreDescriptionDocument"]["pbcorePublisher"].count > 0
          data["pbcoreDescriptionDocument"]["pbcorePublisher"].each_with_index do |publisher,index|
            data["pbcoreDescriptionDocument"]["pbcorePublisher"][index]["publisherRole"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcorePublisher"][index]["publisherRole"])
          end
        end
        data["pbcoreDescriptionDocument"]["pbcoreRightsSummary"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreRightsSummary"])
        if data["pbcoreDescriptionDocument"]["pbcoreRightsSummary"] && data["pbcoreDescriptionDocument"]["pbcoreRightsSummary"].count > 0
          data["pbcoreDescriptionDocument"]["pbcoreRightsSummary"].each_with_index do |publisher,index|
            data["pbcoreDescriptionDocument"]["pbcoreRightsSummary"][index]["rightsSummary"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreRightsSummary"][index]["rightsSummary"])
            data["pbcoreDescriptionDocument"]["pbcoreRightsSummary"][index]["rightsLink"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreRightsSummary"][index]["rightsLink"])
            data["pbcoreDescriptionDocument"]["pbcoreRightsSummary"][index]["rightsEmbedded"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreRightsSummary"][index]["rightsEmbedded"])
          end
        end

        # instantiation
        data["pbcoreDescriptionDocument"]["pbcoreInstantiation"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreInstantiation"])
        #   instantiation contents
        if data["pbcoreDescriptionDocument"]["pbcoreInstantiation"]
          data["pbcoreDescriptionDocument"]["pbcoreInstantiation"].each_with_index do |instantiation,index|

            # stantch fields
            data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationIdentifier"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationIdentifier"])
            # repeatable? unclear
            data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationDate"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationDate"])
            data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationDimensions"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationaDimensions"])
            data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationGenerations"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationGeneratioans"])
            data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationTimeStart"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationTimeStarta"])
            data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationLanguage"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationLanguage"])
            data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationIdentifier"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationIdentifier"])
            data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationAnnotation"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationAnnotation"])

            # who knows!
            data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationPart"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationPart"])
            data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationExtension"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationExtension"])

            # essence tracks
            data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationEssenceTrack"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationEssenceTrack"])
            if data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationEssenceTrack"]
              data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationEssenceTrack"].each_with_index do |esstrack,essindex|

                # essence track contents
                esstrack["essenceTrackIdentifier"] = arrayify_node(esstrack["essenceTrackIdentifier"])
                esstrack["essenceTrackLanguage"] = arrayify_node(esstrack["essenceTrackLanguage"])
                esstrack["essenceTrackIdentifier"] = arrayify_node(esstrack["essenceTrackIdentifier"])
                esstrack["essenceTrackIdentifier"] = arrayify_node(esstrack["essenceTrackIdentifier"])
                esstrack["essenceTrackAnnotation"] = arrayify_node(esstrack["essenceTrackAnnotation"])

                # no repeat
                # essenceTrackType
                # essenceTrackStandard
                # essenceTrackEncoding
                # essenceTrackDataRate
                # essenceTrackFrameRate
                # essenceTrackPlaybackSpeed
                # essenceTrackSamplingRate
                # essenceTrackBitDepth
                # essenceTrackFrameSize
                # essenceTrackAspectRatio
                # essenceTrackTimeStart
                # essenceTrackDuration

                # yikes! oh well
                esstrack["essenceTrackExtension"] = arrayify_node(esstrack["essenceTrackExtension"])

                data["pbcoreDescriptionDocument"]["pbcoreInstantiation"][index]["instantiationEssenceTrack"][essindex] = esstrack
              end
            end
          end
        end

        # no guarantees
        data["pbcoreDescriptionDocument"]["pbcorePart"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcorePart"])
        data["pbcoreDescriptionDocument"]["pbcoreExtension"] = arrayify_node(data["pbcoreDescriptionDocument"]["pbcoreExtension"])

        render json: JSON.pretty_generate( data.compact )
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
      unless node.kind_of?(Array)
        [node]
      else
        node
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

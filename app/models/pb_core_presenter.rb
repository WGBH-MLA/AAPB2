require 'rexml/document'
require 'rexml/xpath'
require 'nokogiri'
require 'solrizer'
require 'fastimage'
require_relative '../../lib/aapb'
require_relative 'exhibit'
require_relative 'special_collection'
require_relative '../../lib/html_scrubber'
require_relative 'xml_backed'
require_relative 'to_mods'
require_relative 'pb_core_name_role_affiliation'
require_relative 'organization'
require_relative '../../lib/formatter'
require_relative '../../lib/caption_converter'
require_relative 'transcript_file'
require_relative 'caption_file'
require_relative '../helpers/application_helper'

require_relative '../helpers/annotation_helper'
require 'active_support/core_ext/module/delegation'

class PBCorePresenter
  def initialize(xml)
    # raise 'No XML passed in for new PBCorePresenter... Whats the point?' unless xml
    # give this meaningless default because some tests pass in nil to pbpresenter?
    @xml = xml || '<pbcoreDescriptionDocument>nogood</pbcoreDescriptionDocument>'
    @pbcore = PBCore::DescriptionDocument.parse(xml)
  end

  attr_accessor :xml
  attr_accessor :pbcore

  delegate :instantiations, to: :pbcore
  delegate :special_collections, to: :pbcore
  delegate :identifiers, to: :pbcore
  delegate :asset_types, to: :pbcore
  delegate :annotations, to: :pbcore

  # rubocop:disable Style/EmptyLineBetweenDefs
  # include XmlBacked
  include ToMods
  include ApplicationHelper
  include AnnotationHelper

  #  access helpers
  def pairs_by_type(elements, key)
    elements.map do |ele|
      [
        # get attribute value where available
        (defined? ele.send(key)) ? ele.send(key) : nil,
        ele.value
      ]
    end
  end

  def people_data(people, type)
    people.map do |peep|
      role = peep.role.value if peep.role
      peep_obj = peep.send(type)
      name = peep_obj.value if peep_obj
      affiliation = peep_obj.affiliation if peep_obj
      PBCoreNameRoleAffiliation.new(name, role, affiliation)
    end
  end

  def descriptions
    @descriptions ||= @pbcore.descriptions.map { |description| HtmlScrubber.scrub(description.value).gsub(/[\s\n]+/, ' ').strip if description.value }
  end
  def genres
    @genres ||= @pbcore.genres.select { |genre| genre.annotation == 'genre' }.map(&:value)
  end
  def topics
    @topics ||= @pbcore.genres.select { |genre| genre.annotation == 'topic' }.map(&:value)
  end
  def subjects
    @subjects ||= @pbcore.subjects.map(&:value)
  end
  def creators
    @creators ||= people_data(@pbcore.creators, :creator)
  end
  def contributors
    @contributors ||= people_data(@pbcore.contributors, :contributor)
  end
  def publishers
    @publishers ||= people_data(@pbcore.publishers, :publisher)
  end
  def all_parties
    cre = creators || []
    con = contributors || []
    pub = publishers || []
    (cre + con + pub).uniq.sort_by { |p| p.role ? p.role : '' }
  end
  def producing_organizations
    @producing_organizations ||= creators.select { |org| org.role == 'Producing Organization' }
  end
  def producing_organizations_facet
    @producing_organizations_facet ||= producing_organizations.map(&:name) unless producing_organizations.empty?
  end

  def instantiations_display
    # @instantiations_display ||= instantiations.reject { |i| annotations_by_type(i.annotations, 'organization').any? {|a| a.value == 'American Archive of Public Broadcasting'}  }
    @instantiations_display ||= instantiations.reject { |i| annotations_by_type(i.annotations, 'organization').any? { |a| a.value == 'American Archive of Public Broadcasting' } }.map { |i| PBCoreInstantiationPresenter.new(i.to_xml) }
  end
  def rights_summaries
    @rights_summaries ||= @pbcore.rights_summaries.map { |rights| rights.rights_summary.value if rights.rights_summary }
  end
  def asset_type
    @asset_type ||= asset_types.first.value if asset_types.first
  end
  def asset_dates
    @asset_dates ||= pairs_by_type(@pbcore.asset_dates, :type)
  end
  def asset_date
    @asset_date ||= @pbcore.asset_dates.first.value if @pbcore.asset_dates.first
  end
  def licensing_info
    @licensing_info ||= annotations_by_type(@pbcore.annotations, 'Licensing Info').join(' ')
  end
  def titles
    # give em a hash
    @titles ||= @pbcore.titles.inject(Hash.new([])) do |h, a|
      h[a.type] += [a.value]
      h
    end
  end
  def title
    @title ||= build_display_title
  end
  def episode_number_sort
    @episode_number_sort ||= titles.select { |title| title[0] == "Episode Number" }.map(&:last).sort.first
  end
  def exhibits
    @exhibits ||= Exhibit.find_all_by_item_id(id)
  end
  def special_collections
    @special_collections ||= annotations_by_type(annotations, 'special_collections')
  end
  def id
    # Solr IDs need to have "cpb-aacip_" instead of "cpb_aacip/" for proper lookup in Solr.
    # Some IDs (e.g. Mississippi) may have "cpb-aacip-", but that's OK.
    # TODO: https://github.com/WGBH/AAPB2/issues/870
    @id ||= begin
      ideez = identifiers.select { |id| id.source == 'http://americanarchiveinventory.org' }
      raise "Only one AAPB GUID is allowed per record!" unless ideez.count == 1
      ideez.first.value.gsub('cpb-aacip/', 'cpb-aacip_')
    end
  end
  SONY_CI = 'Sony Ci'.freeze
  def ids
    @ids ||= begin
      aapbid = nil
      some_ids = identifiers.map do |id|
        if id.source == 'http://americanarchiveinventory.org'
          aapbid = id
          next
        elsif id.source != SONY_CI
          [id.source, id.value]
        end
      end.compact

      aapbid ? some_ids.unshift(['AAPB ID', aapbid.value]) : some_ids
    end
  end
  def ci_ids
    @ci_ids ||= identifiers.select { |id| id.source == SONY_CI }.map(&:value)
  end
  def display_ids
    @display_ids ||= ids.keep_if { |i| i[0] == 'AAPB ID' || i[0].downcase.include?('nola') }
  end
  def media_srcs
    @media_srcs ||= (1..ci_ids.count).map { |part| "/media/#{id}?part=#{part}" }
  end
  CAPTIONS_ANNOTATION = 'Captions URL'.freeze
  def captions_src
    @captions_src ||= one_annotation_by_type(@pbcore.annotations, CAPTIONS_ANNOTATION)
  end
  TRANSCRIPT_ANNOTATION = 'Transcript URL'.freeze
  def transcript_src
    @transcript_src ||= one_annotation_by_type(@pbcore.annotations, TRANSCRIPT_ANNOTATION)
  end

  def img?
    media_type == MOVING_IMAGE && digitized?
  end

  def id_for_s3
    id.gsub(/cpb-aacip-/, 'cpb-aacip_')
  end

  def img_src(icon_only = false)
    @img_src ||= begin
      url = nil
      if media_type == MOVING_IMAGE && digitized? && !icon_only
        url = "#{AAPB::S3_BASE}/thumbnail/#{id_for_s3}.jpg"
      end

      unless url
        url = case [media_type, digitized?]
              # when [MOVING_IMAGE, true]
              # TODO: Move ID cleaning into Cleaner: https://github.com/WGBH/AAPB2/issues/870
              # Mississippi IDs have dashes, but they cannot for image URLs on S3. All S3 image URLs use "cpb-aacip_".
              # "#{AAPB::S3_BASE}/thumbnail/#{id.gsub(/cpb-aacip-/,'cpb-aacip_')}.jpg"
              when [MOVING_IMAGE, false]
                '/thumbs/VIDEO_NOT_DIG.png'
              when [SOUND, true]
                '/thumbs/AUDIO.png'
              when [SOUND, false]
                '/thumbs/AUDIO_NOT_DIG.png'
              else
                '/thumbs/OTHER.png'
              end
      end

      url
    end
    # NOTE: ToMods assumes path-only URLs are locals not to be shared with DPLA.
    # If these got moved to S3, that would need to change.
  end
  def img_height
    @img_height = img_dimensions[1]
  end
  def img_width
    @img_width = img_dimensions[0]
  end
  def contributing_organization_names
    @contributing_organization_names ||= annotations_by_type(instantiations.map(&:annotations).flatten, 'organization').map(&:value).uniq
  end
  def contributing_organizations_facet
    @contributing_organizations_facet ||= contributing_organization_objects.map(&:facet) unless contributing_organization_objects.empty?
  end
  def contributing_organization_objects
    @contributing_organization_objects ||= Organization.organizations(contributing_organization_names)
  end
  def contributing_organization_names_display
    @contributing_organization_names_display ||= Organization.build_organization_names_display(contributing_organization_objects)
  end
  def states
    @states ||= contributing_organization_objects.map(&:state)
  end
  def outside_url
    @outside_url ||= begin
      url_anno = annotations_by_type(@pbcore.annotations, 'Outside URL')
      if url_anno.present?
        raise("If there is an Outside URL, the record must be explicitly public -- #{id} #{access_level}") unless public?
        url_anno.first.value
      end
    end
  end
  def outside_baseurl
    return nil unless outside_url
    baseurl = URI(outside_url.start_with?('http://', 'https://') ? outside_url : %(http://#{outside_url})).host
    baseurl.to_s.start_with?('www.') ? baseurl.gsub('www.', '') : baseurl
  end
  def reference_urls
    # These only provide extra information. We aren't saying there is media on the far side,
    # so this has no interaction with access_level, unlike outside_url.
    @reference_urls ||= annotations_by_type(@pbcore.annotations, 'External Reference URL').map(&:value)
  end
  def access_level
    @access_level ||= begin
      access_levels = annotations_by_type(@pbcore.annotations, 'Level of User Access').map(&:value)
      raise('Should have at most 1 "Level of User Access" annotation') if access_levels.count > 1
      raise('Should have "Level of User Access" annotation if digitized') if digitized? && access_levels.count == 0
      raise('Should not have "Level of User Access" annotation if not digitized') if !digitized? && access_levels.count != 0
      access_levels.first # Returns nil for non-digitized
    end
  end
  def public? # AKA online reading room
    access_level == 'Online Reading Room'
  end
  def protected? # AKA on site
    access_level == 'On Location'
  end
  def private? # AKA not even on site
    access_level == 'Private' # TODO: Confirm that this is the right string.
  end
  def access_level_description
    return 'Online Reading Room' if public?
    return 'Accessible on location at WGBH and the Library of Congress. ' if protected?
  end
  CORRECT_TRANSCRIPT = 'Correct'.freeze
  CORRECTING_TRANSCRIPT = 'Correcting'.freeze
  UNCORRECTED_TRANSCRIPT = 'Uncorrected'.freeze
  def transcript_status
    @transcript_status ||= one_annotation_by_type(@pbcore.annotations, 'Transcript Status')
  end
  def transcript_content
    return nil unless transcript_src
    transcript_file = TranscriptFile.new(transcript_src)
    return transcript_file.content if transcript_file
    caption_file = CaptionFile.new(captions_src)
    return caption_file.json if caption_file && caption_file.json
    nil
  end
  MOVING_IMAGE = 'Moving Image'.freeze
  SOUND = 'Sound'.freeze
  OTHER = 'other'.freeze
  def media_type
    @media_type ||= begin
      media_types = instantiations.map(&:media_type).map(&:value)
      [MOVING_IMAGE, SOUND, OTHER].each do |type|
        return type if media_types.include? type
      end
      return OTHER if media_types == [] # pbcoreInstantiation is not required, so this is possible
      raise "Unexpected media types: #{media_types.uniq}"
    end
  end
  def video?
    media_type == MOVING_IMAGE
  end
  def audio?
    media_type == SOUND
  end
  def duration
    @duration ||= instantiations.find { |i| break i.duration.value if i.duration }
  end
  def player_aspect_ratio
    @player_aspect_ratio ||= begin
      instantiations.first.essence_tracks.first.aspect_ratio.value
    rescue
      '4:3'
    end
  end
  def player_specs
    case player_aspect_ratio
    when '16:9'
      [AAPB::PLAYER_WIDTH_NO_TRANSCRIPT_16_9, AAPB::PLAYER_HEIGHT_NO_TRANSCRIPT_16_9]
    else
      [AAPB::PLAYER_WIDTH_NO_TRANSCRIPT_4_3, AAPB::PLAYER_HEIGHT_NO_TRANSCRIPT_4_3]
    end
  end
  def digitized?
    @digitized ||= !ci_ids.empty?
    # TODO: not confident about this. We ought to be able to rely on this:
    # xpaths('/*/pbcoreInstantiation/instantiationGenerations').include?('Proxy')
  end
  ALL_ACCESS = 'all'.freeze             # includes non-digitized
  PUBLIC_ACCESS = 'online'.freeze       # digitized
  PROTECTED_ACCESS = 'on-location'.freeze # digitized
  PRIVATE_ACCESS = 'private'.freeze     # digitized
  DIGITIZED_ACCESS = 'digitized'.freeze # public or protected, but not private
  def access_types
    @access_types ||= [ALL_ACCESS].tap do |types|
      types << PUBLIC_ACCESS if public?
      types << PROTECTED_ACCESS if protected?
      types << PRIVATE_ACCESS if private?
      types << DIGITIZED_ACCESS if digitized? && !private?
    end
  end
  # Playlist functionality from OpenVault
  def playlist_group
    @playlist_group ||= one_annotation_by_type(@pbcore.annotations, 'Playlist Group')
  end
  def playlist_order
    @playlist_order ||= begin
      anno = one_annotation_by_type(@pbcore.annotations, 'Playlist Order')
      anno ? anno.to_i : nil
    end
  end

  # TODO: This could be done with claen, sustainable solr queries to avoid using map here
  def playlist_map
    @playlist_map ||= begin
      response = RSolr.connect(url: 'http://localhost:8983/solr/').get('select', params:
      {
        'fl' => 'playlist_order,id',
        'fq' => "playlist_group:#{playlist_group}",
        'rows' => '100'
      })
      Hash[response['response']['docs'].map { |doc| [doc['playlist_order'].to_i, doc['id']] }]
    end if playlist_group
  end
  def playlist_next_id
    @playlist_next_id ||= begin
      playlist_map[playlist_map.keys.select { |k| k > playlist_order }.min]
    end if playlist_map
  end
  def playlist_prev_id
    @playlist_prev_id ||= begin
      playlist_map[playlist_map.keys.select { |k| k < playlist_order }.max]
    end if playlist_map
  end
  def supplemental_content
    @supplemental_content ||= annotations_by_type(@pbcore.annotations, 'Supplemental Material').map { |mat| [mat.ref, mat.value] }
  end

  # rubocop:enable Style/EmptyLineBetweenDefs

  # TODO: modify this for captions for vtt source file change?
  def self.srt_url(id)
    # Class method because it doesn't depend on object state,
    # and we want to get at it without a full instantiation.
    caption_id = id.tr('_', '-')
    caption_base = 'https://s3.amazonaws.com/americanarchive.org/captions'
    "#{caption_base}/#{caption_id}/#{caption_id}.srt1.srt"
  end

  def to_solr
    # Only just before indexing do we check for the existence of captions:
    # We don't want to ping S3 multiple times, and we don't want to store all
    # of a captions/transcript file in solr (much less in the pbcore).
    # --> We only want to say that it exists, and we want to index the words.

    # REXML::Document
    full_doc = REXML::Document.new(@xml)
    spot_for_annotations = ['//pbcoreInstantiation[last()]',
                            '//pbcoreRightsSummary[last()]',
                            '//pbcorePublisher[last()]',
                            '//pbcoreContributor[last()]',
                            '//pbcoreCreator[last()]',
                            '//pbcoreCoverage[last()]',
                            '//pbcoreGenre[last()]',
                            '//pbcoreDescription[last()]'
                          ].detect { |xp| REXML::XPath.match(full_doc, xp).present? }

    caption_response = !captions_src.nil? ? Net::HTTP.get_response(URI.parse(captions_src)) : nil
    if !caption_response.nil? && caption_response.code == '200'
      pre_existing = pre_existing_caption_annotation(full_doc)
      pre_existing.parent.elements.delete(pre_existing) if pre_existing
      caption_body = parse_caption_body(CaptionConverter.srt_to_text(caption_response.body))

      cap_anno = REXML::Element.new('pbcoreAnnotation').tap do |el|
        el.add_attribute('annotationType', CAPTIONS_ANNOTATION)
        el.add_text(captions_src)
      end

      full_doc.insert_after(spot_for_annotations, cap_anno)
    end

    transcript_file = !transcript_src.nil? ? TranscriptFile.new(transcript_src) : nil
    if !transcript_file.nil? && transcript_file.file_present?
      pre_existing = pre_existing_transcript_annotation(full_doc)
      pre_existing.parent.elements.delete(pre_existing) if pre_existing
      transcript_body = Nokogiri::HTML(transcript_file.html).text.tr("\n", ' ')

      trans_anno = REXML::Element.new('pbcoreAnnotation').tap do |el|
        el.add_attribute('annotationType', TRANSCRIPT_ANNOTATION)
        el.add_text(transcript_src)
      end

      full_doc.insert_after(spot_for_annotations, trans_anno)
    end

    {
      'id' => id,
      'xml' => @xml,

      # constrained searches:
      'text' => text + [caption_body].select { |optional| optional } + [transcript_body].select { |optional| optional },
      'titles' => titles.values.flatten,
      'episode_number_sort' => episode_number_sort,
      'contribs' => contribs,

      # sort:
      'title' => title,

      # sort and facet:
      'year' => year,
      'asset_date' => date_for_assetdate_field,

      # facets:
      'exhibits' => exhibits.map(&:path),
      'special_collections' => special_collections,
      'media_type' => media_type == OTHER ? nil : media_type,
      'genres' => genres,
      'topics' => topics,
      'asset_type' => asset_type,
      'contributing_organizations' => contributing_organizations_facet,
      'producing_organizations' => producing_organizations_facet,
      'states' => states,
      'access_types' => access_types,

      # playlist
      'playlist_group' => playlist_group,
      'playlist_order' => playlist_order
      # format keys for solr's pleasure
      # rubocop:disable Style/Semicolon
      # rubocop:disable Style/SingleLineBlockParams
    }.merge(titles.inject(Hash.new([])) { |h, data| h["#{data.first.downcase.tr(' ', '_')}_titles"] += data[1]; h })
    # rubocop:enable Style/Semicolon
    # rubocop:enable Style/SingleLineBlockParams
  end

  private

  # These methods are only used by to_solr.

  def text
    ignores = [
      :text, :to_solr, :contribs, :img_src, :media_srcs,
      :captions_src, :transcript_src, :rights_code,
      :access_level, :access_types, :title, :ci_ids, :display_ids,
      :instantiations, :outside_url,
      :reference_urls, :exhibits, :special_collections, :access_level_description,
      :img_height, :img_width, :player_aspect_ratio,
      :player_specs, :transcript_status, :transcript_content,
      :playlist_group, :playlist_order, :playlist_map,
      :playlist_next_id, :playlist_prev_id, :supplemental_content, :contributing_organization_names,
      :contributing_organizations_facet, :contributing_organization_names_display, :producing_organizations,
      :producing_organizations_facet, :build_display_title, :licensing_info, :instantiations_display, :outside_baseurl,
      # helpers
      :pairs_by_type, :annotations_by_type, :one_annotation_by_type, :people_data, :title_html, :all_parties, :instantiations, :asset_types, :annotations,
      # duh
      :xml, :xml=, :pbcore=, :asset_types, :identifiers, :pbcore
    ]

    @text ||= (PBCorePresenter.instance_methods(false) - ignores)
              .reject { |method| method =~ /\?$/ } # skip booleans
              .map { |method| send(method) } # method -> value
              .flatten # flattens list accessors
              .compact # skip nils
              .map { |x| x.respond_to?(:to_a) ? x.to_a : x } # get elements of compounds
              .flatten
              .map { |x| x.respond_to?(:value) ? x.value : x } # get values from pbcore gem elements
              .uniq.compact.sort
  end

  def build_display_title
    titles_by_type = titles

    titles_to_join =  if titles_by_type['Series'].count > 1 && titles_by_type['Episode Number'] && titles_by_type['Episode']
                        titles_by_type['Episode']
                      elsif titles_by_type['Episode Number'].count > 1 && titles_by_type['Series'].count == 1 && titles_by_type['Episode']
                        (titles_by_type['Series'] + titles_by_type['Episode'])
                      elsif titles_by_type['Alternative'] && titles_by_type.keys.length == 1
                        titles_by_type['Alternative']
                      else
                        unalternative = []
                        titles_by_type.each { |type, titles| unalternative += titles if type != 'Alternative' }
                        unalternative
                      end

    titles_to_join.sort.join('; ')
  end

  def contribs
    @contribs ||=
      (creators.map { |creator| [creator.name, creator.affiliation] } +
            contributors.map { |contributor| [contributor.name, contributor.affiliation] } + publishers.map { |publisher| [publisher.name, publisher.affiliation] }).flatten
  end

  def year
    @year ||= asset_date ? asset_date.gsub(/-\d\d-\d\d/, '') : nil
  end

  def date_for_assetdate_field
    date_val = asset_date
    return unless date_val
    handle_date_string(date_val, 'index')
  end

  # These can stay, because they are for manipulating the raw xml for to_solr
  def pre_existing_caption_annotation(doc)
    REXML::XPath.match(doc, "//pbcoreAnnotation[@annotationType='#{CAPTIONS_ANNOTATION}']").first
  end

  def pre_existing_transcript_annotation(doc)
    REXML::XPath.match(doc, "//pbcoreAnnotation[@annotationType='#{TRANSCRIPT_ANNOTATION}']").first
  end

  def parse_caption_body(caption_body)
    # "\n" is not in the [:print:] class, but it should be preserved.
    # "&&" is intersection: we also want to match " ",
    # so that control-chars + spaces collapse to a single space.
    caption_body.gsub(/[^[:print:][\n]&&[^ ]]+/, ' ')
  end

  def img_dimensions
    @img_dimensions ||= (FastImage.size(@img_src) || [300, 225])
  end
end

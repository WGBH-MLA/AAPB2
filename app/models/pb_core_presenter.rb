require 'rexml/document'
require 'rexml/xpath'
require 'nokogiri'
require 'solrizer'
require 'fastimage'
require 'httparty'
require_relative '../../lib/aapb'
require_relative 'exhibit'
require_relative 'special_collection'
require_relative '../../lib/html_scrubber'
require_relative 'xml_backed'
require_relative 'to_mods'
require_relative 'iiif_manifest'
require_relative 'pb_core_instantiation'
require_relative 'pb_core_name_role_affiliation'
require_relative 'organization'
require_relative '../../lib/formatter'
require_relative '../../lib/caption_converter'
require_relative 'transcript_file'
require_relative 'caption_file'
require_relative '../helpers/application_helper'
require_relative 'canonical_url'
require_relative '../helpers/id_helper'

class PBCorePresenter
  # rubocop:disable Style/EmptyLineBetweenDefs
  include XmlBacked
  include ToMods
  include IIIFManifest
  include ApplicationHelper
  include IdHelper

  def descriptions
    @descriptions ||= xpaths('/*/pbcoreDescription').map { |description| HtmlScrubber.scrub(description) }
  end
  def descriptions_with_types
    @descriptions_with_types ||= pairs_by_type('/*/pbcoreDescription', '@descriptionType').map! do |pair|
      pair.map! { |value| value.nil? ? "" : HtmlScrubber.scrub(value) }
      pair[0].nil? ? pair[0] = "Description" : pair[0]
      pair[1].nil? ? pair[1] = "" : pair[1]
      [pair[0], pair[1]]
    end
  end
  def sorted_descriptions
    (descriptions_with_types.select { |pair| pair[0] == "Episode" } +
     descriptions_with_types.select { |pair| pair[0] == "Program" } +
     descriptions_with_types.select { |pair| pair[0] == "Description" } +
     descriptions_with_types.select { |pair| pair[0] == "Series" } +
     descriptions_with_types).uniq
  end
  def display_descriptions
    @display_descriptions ||= sorted_descriptions.map! { |desc|
      [(desc[0].strip.downcase != "description" ? "#{desc[0].strip} Description" : "Other Description"), desc[1]]
    }
  end
  def genres
    @genres ||= xpaths('/*/pbcoreGenre[@annotation="genre"]')
  end
  def topics
    @topics ||= xpaths('/*/pbcoreGenre[@annotation="topic"]')
  end
  def subjects
    @subjects ||= xpaths('/*/pbcoreSubject')
  end
  def producing_organizations
    @producing_organizations ||= creators.select { |org| org.role == 'Producing Organization' }
  end
  def producing_organizations_facet
    @producing_organizations_facet ||= producing_organizations.map(&:name) unless producing_organizations.empty?
  end
  def creators
    @creators ||= REXML::XPath.match(@doc, '/*/pbcoreCreator').map do |rexml|
      PBCoreNameRoleAffiliation.new(rexml)
    end
  end
  def contributors
    @contributors ||= REXML::XPath.match(@doc, '/*/pbcoreContributor').map do |rexml|
      PBCoreNameRoleAffiliation.new(rexml)
    end
  end
  def publishers
    @publishers ||= REXML::XPath.match(@doc, '/*/pbcorePublisher').map do |rexml|
      PBCoreNameRoleAffiliation.new(rexml)
    end
  end
  def all_parties
    cre = creators || []
    con = contributors || []
    pub = publishers || []
    (cre + con + pub).uniq.sort_by { |p| p.role ? p.role : '' }
  end
  def instantiations
    @instantiations ||= REXML::XPath.match(@doc, '/*/pbcoreInstantiation').map do |rexml|
      PBCoreInstantiation.new(rexml)
    end
  end

  def digital_instantiations
    instantiations.select(&:digital)
  end

  def physical_instantiations
    instantiations.select(&:physical)
  end

  def instantiations_display
    @instantiations_display ||= instantiations.reject { |ins| ins.organization == 'American Archive of Public Broadcasting' }
  end
  def rights_summaries
    @rights_summaries ||= xpaths('/*/pbcoreRightsSummary/rightsSummary')
  rescue NoMatchError
    nil
  end
  def licensing_info
    @licensing_info ||= xpath('/*/pbcoreAnnotation[@annotationType="Licensing Info"]')
  rescue NoMatchError
    nil
  end
  def asset_type
    @asset_type ||= xpath('/*/pbcoreAssetType')
  rescue NoMatchError
    nil
  end
  def asset_dates
    @asset_dates ||= pairs_by_type('/*/pbcoreAssetDate', '@dateType').map do |pair|
      pair.map { |value| value.nil? ? "" : value.strip }
    end
  end
  def asset_date
    @asset_date ||= xpath('/*/pbcoreAssetDate[1]')
  rescue NoMatchError
    nil
  end
  def display_asset_dates
    @display_asset_dates ||= asset_dates.map! { |date|
      [((date[0].strip.downcase != "copyright date" && date[0].strip.downcase != "date") ? "#{date[0]} Date".strip : date[0]), date[1]]
    }
  end
  def titles
    @titles ||= pairs_by_type('/*/pbcoreTitle', '@titleType')
  end
  def title
    @title ||= build_display_title
  end
  def episode_number_sort
    @episode_number_sort ||= titles.select { |title| title[0] == "Episode Number" }.map(&:last).sort.first
  end
  def exhibits
    @exhibits ||= id_styles(id).map { |style| Exhibit.find_all_by_item_id(style) }.flatten
  end
  def top_exhibits
    @top_exhibits ||= id_styles(id).map { |style| Exhibit.find_top_by_item_id(style) }.flatten.uniq
  end
  def special_collections
    @special_collections ||= xpaths('/*/pbcoreAnnotation[@annotationType="special_collections"]')
  end
  def original_id
    # just normalize guid thats in the xml
    @original_id ||= xpath('/*/pbcoreIdentifier[@source="http://americanarchiveinventory.org"]')
  end
  # Normalizes to dash
  def id
    normalize_guid(original_id)
  end
  SONY_CI = 'Sony Ci'.freeze
  def ids
    @ids ||= begin
      h = hash_by_type('/*/pbcoreIdentifier', '@source') # TODO: confirm multi-hash not necessary.
      h.delete(SONY_CI) # Handled separately
      { 'AAPB ID' => h.delete('http://americanarchiveinventory.org') }.merge(h).map { |key, value| [key, value] }
      # Relabel AND put at front of list.
      # Map to pairs for consistency... but building the hash and just throwing it away?
    end
  end
  def ci_ids
    @ci_ids ||= xpaths("/*/pbcoreIdentifier[@source='#{SONY_CI}']")
  end
  def display_ids
    @display_ids ||= ids.keep_if { |i| i[0] == 'AAPB ID' || i[0].downcase.include?('nola') }
  end
  # Uses normalized GUID
  def media_srcs
    @media_srcs ||= (1..ci_ids.count).map { |part| "/media/#{id}?part=#{part}" }
  end
  CAPTIONS_ANNOTATION = 'Captions URL'.freeze
  def captions_src
    @captions_src ||= xpath("/*/pbcoreAnnotation[@annotationType='#{CAPTIONS_ANNOTATION}']")
  rescue NoMatchError
    nil
  end
  TRANSCRIPT_ANNOTATION = 'Transcript URL'.freeze
  def transcript_src
    @transcript_src ||= xpath("/*/pbcoreAnnotation[@annotationType='#{TRANSCRIPT_ANNOTATION}']")
  rescue NoMatchError
    nil
  end
  def constructed_transcript_src
    @constructed_transcript_url ||= begin
      # transcript guids are expected to have -
      trans_id = normalize_guid(id)

      # Map 'json' and 'txt' file extensions to full transcript URLs to look for.
      urls = %w(json txt).map do |ext|
        %(https://s3.amazonaws.com/americanarchive.org/transcripts/#{trans_id}/#{trans_id}-transcript.#{ext})
      end

      # Return the first verified URL; nil if none can be verified.
      urls.detect { |url| verify_transcript_src(url) }
    end
  end
  def verify_transcript_src(url)
    HTTParty.head(url).code == 200
  end
  def img?
    media_type == MOVING_IMAGE && digitized?
  end
  def img_src(icon_only = false)
    @img_src ||= begin
      expected_url = "#{AAPB::S3_BASE}/thumbnail/#{id}.jpg"
      thumbnail = ExternalFile.new("thumbnail", id, expected_url)

      if !icon_only && (media_type == MOVING_IMAGE && digitized? || thumbnail.file_present?)

        # moving image + digitized htumbs are conventionally expected to be there, so save the head request
        expected_url
      else
        case [media_type, digitized?]
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
    @contributing_organization_names ||= Organization.clean_organization_names(xpaths('/*/pbcoreInstantiation/instantiationAnnotation[@annotationType="organization"]').uniq)
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
  rescue NoMatchError
    nil
  end
  def outside_urls
    @outside_urls ||= begin
      outside_urls = xpaths('/*/pbcoreAnnotation[@annotationType="Outside URL"]')
      raise('If there is an Outside URL, the record must be explicitly public') if outside_urls.present? && !public?
      outside_urls
    end
  rescue NoMatchError
    nil
  end
  def outside_baseurl(url)
    baseurl = URI(url.start_with?('http://', 'https://') ? url : %(http://#{url})).host
    baseurl.to_s.start_with?('www.') ? baseurl.gsub('www.', '') : baseurl
  end
  def reference_urls
    # These only provide extra information. We aren't saying there is media on the far side,
    # so this has no interaction with access_level, unlike outside_urls.
    @reference_urls ||= begin
      xpaths('/*/pbcoreAnnotation[@annotationType="External Reference URL"]')
    end
  rescue NoMatchError
    nil
  end
  def canonical_url
    @canonical_url ||= CanonicalUrl.new(id).url
  end
  def access_level
    @access_level ||= begin
      access_levels = xpaths('/*/pbcoreAnnotation[@annotationType="Level of User Access"]')
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
    return 'Accessible on location at GBH and the Library of Congress. ' if protected?
  end
  CORRECT_TRANSCRIPT = 'Correct'.freeze
  CORRECTING_TRANSCRIPT = 'Correcting'.freeze
  UNCORRECTED_TRANSCRIPT = 'Uncorrected'.freeze
  def transcript_status
    @transcript_status ||= xpath('/*/pbcoreAnnotation[@annotationType="Transcript Status"]')
  rescue NoMatchError
    nil
  end
  def transcript_content
    return nil unless transcript_src
    transcript_file = TranscriptFile.new(id, transcript_src)
    return transcript_file.file_content if transcript_file.file_present?
    caption_file = CaptionFile.retrieve_captions(id)
    return caption_file.json if caption_file.file_present? && caption_file.json
    nil
  end
  def uncorrected_transcript?
    transcript_status == PBCorePresenter::UNCORRECTED_TRANSCRIPT
  end
  def correcting_transcript?
    transcript_status == PBCorePresenter::CORRECTING_TRANSCRIPT
  end
  def correct_transcript?
    transcript_status == PBCorePresenter::CORRECT_TRANSCRIPT
  end
  def transcript_html(start_time = nil, end_time = nil)
    tfile = TranscriptFile.new(id, transcript_src, start_time, end_time) if transcript_src
    return tfile.html if tfile && tfile.file_present?
    captions = CaptionFile.retrieve_captions(id)
    return captions.html if captions.file_present?
    nil
  end
  def transcript_message
    @transcript_message ||= begin 
      if uncorrected_transcript? 
        'This transcript was received from a third party and/or generated by a computer. Its accuracy has not been verified. If this transcript has significant errors that should be corrected, <a href="mailto:aapb_notifications@wgbh.org">let us know</a>, so we can add it to <a href="https://fixitplus.americanarchive.org">FIX IT+</a>.'
      elsif correcting_transcript? 
        "Help us correct this transcription at http://fixitplus.americanarchive.org/transcripts/#{id}"
      elsif correct_trancript?
        'This transcript has been examined and corrected by a human. Most of our transcripts are computer-generated, then edited by volunteers using our <a href="https://fixitplus.americanarchive.org">FIX IT+</a> crowdsourcing tool. If this transcript needs further correction, please <a href="mailto:aapb_notifications@wgbh.org">let us know</a>.'
      end
    end
  end
  MOVING_IMAGE = 'Moving Image'.freeze
  SOUND = 'Sound'.freeze
  OTHER = 'other'.freeze
  def media_type
    @media_type ||= begin
      media_types = xpaths('/*/pbcoreInstantiation/instantiationMediaType')
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
    # for AAPB, the (preferred) machine-generated duration is always expected to be
    # a) inside a pbcoreInstantiation that has an instantiationGenerations with the text "Proxy"
    # b) in an instantiationEssenceTrack/essenceTrackDuration
    # if you cant find that, choose another essenceTrackDuration
    @duration ||= begin
      proxy_node = REXML::XPath.match(@doc, '/*/pbcoreInstantiation/instantiationGenerations[text()="Proxy"]/..').first
      proxy_duration_node = REXML::XPath.match(proxy_node, 'instantiationEssenceTrack/essenceTrackDuration') if proxy_node
      return proxy_duration_node.first.text if proxy_duration_node.present?
      any_duration_node = REXML::XPath.match(@doc, '/*/pbcoreInstantiation/instantiationEssenceTrack/essenceTrackDuration').first
      any_duration_node.text if any_duration_node.present?
    end
  end
  def seconds
    dur = duration
    return 0 unless dur
    parts = dur.split(':')
    hours = parts[0].to_i * 3600
    mins = parts[1].to_i * 60
    secs = parts[2].to_i
    hours + mins + secs
  end
  def player_aspect_ratio
    @player_aspect_ratio ||= begin
      instantiations.find { |i| !i.aspect_ratio.nil? }.aspect_ratio
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
    @playlist_group ||= xpath_optional('/*/pbcoreAnnotation[@annotationType="Playlist Group"]')
  end
  def playlist_order
    @playlist_order ||= xpath_optional('/*/pbcoreAnnotation[@annotationType="Playlist Order"]').to_i
  end
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
    @supplemental_content ||= begin
      REXML::XPath.match(@doc, '/*/pbcoreAnnotation[@annotationType="Supplemental Material"]').map { |mat| [mat.attributes['ref'], mat.text] }
    end
  end
  def proxy_start_time
    @proxy_start_time ||= convert_timestamp_to_seconds(xpath('/*/pbcoreAnnotation[@annotationType="Proxy Start Time"]'))
  rescue
    nil
  end
  # rubocop:enable Style/EmptyLineBetweenDefs

  def to_solr
    # Only just before indexing do we check for the existence of captions:
    # We don't want to ping S3 multiple times, and we don't want to store all
    # of a captions/transcript file in solr (much less in the pbcore).
    # --> We only want to say that it exists, and we want to index the words.

    # REXML::Document
    full_doc = @doc.deep_clone
    spot_for_annotations = ['//pbcoreInstantiation[last()]',
                            '//pbcoreRightsSummary[last()]',
                            '//pbcorePublisher[last()]',
                            '//pbcoreContributor[last()]',
                            '//pbcoreCreator[last()]',
                            '//pbcoreCoverage[last()]',
                            '//pbcoreGenre[last()]',
                            '//pbcoreDescription[last()]'
                          ].detect { |xp| xpaths(xp).count > 0 }

    # This verifies that there is a corresponding file on S3 and adds
    # a PBCore annotation required for AAPB but not coming from AMS or AMS2
    captions = CaptionFile.retrieve_captions(id)
    if captions.file_present?

      pre_existing = pre_existing_caption_annotation(full_doc)
      pre_existing.parent.elements.delete(pre_existing) if pre_existing

      caption_body = captions.text

      cap_anno = REXML::Element.new('pbcoreAnnotation').tap do |el|
        el.add_attribute('annotationType', CAPTIONS_ANNOTATION)
        el.add_text(captions.captions_src)
      end

      full_doc.insert_after(spot_for_annotations, cap_anno)
    end

    # if transcript status exists in pbcore, put the transcript url annotation in
    if transcript_status
      transcript_file = TranscriptFile.new(id, constructed_transcript_src)

      if transcript_file.file_present?(force_check: true)

        pre_existing = pre_existing_transcript_annotation(full_doc)
        pre_existing.parent.elements.delete(pre_existing) if pre_existing
        transcript_body = Nokogiri::HTML(transcript_file.html).text.tr("\n", ' ')

        trans_anno = REXML::Element.new('pbcoreAnnotation').tap do |el|
          el.add_attribute('annotationType', TRANSCRIPT_ANNOTATION)
          el.add_text(constructed_transcript_src)
        end

        full_doc.insert_after(spot_for_annotations, trans_anno)
      end
    end

    {
      'id' => id,
      'xml' => Formatter.instance.format(full_doc),

      # constrained searches:
      'text' => text + [caption_body].select { |optional| optional } + [transcript_body].select { |optional| optional },
      'titles' => titles.map(&:last),
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
    }.merge(
      # fills dynamic field *_titles with stuff like series_titles, program_titles, etc
      Hash[
        titles.group_by { |pair| pair[0] }.map do |key, pairs|
          ["#{key.downcase.tr(' ', '_')}_titles", pairs.map { |pair| pair[1] }]
        end
      ]
    )
  end

  private

  # These methods are only used by to_solr.

  def text
    ignores = [
      :text, :to_solr, :contribs, :img_src, :media_srcs,
      :captions_src, :transcript_src, :rights_code,
      :access_level, :access_types, :title, :ci_ids, :display_ids,
      :instantiations, :digital_instantiations, :physical_instantiations, :digital, :physical, :outside_urls,
      :reference_urls, :exhibits, :top_exhibits, :special_collections, :access_level_description,
      :img_height, :img_width, :player_aspect_ratio, :seconds,
      :player_specs, :transcript_status, :transcript_content, :constructed_transcript_src, :verify_transcript_src,
      :playlist_group, :playlist_order, :playlist_map,
      :playlist_next_id, :playlist_prev_id, :supplemental_content, :contributing_organization_names,
      :contributing_organizations_facet, :contributing_organization_names_display, :producing_organizations,
      :producing_organizations_facet, :build_display_title, :licensing_info, :instantiations_display, :outside_baseurl, :original_id,
      :transcript_html, :fixitplus_url, :transcript_message, :proxy_start_time,
      :sorted_descriptions, :display_descriptions, :display_asset_dates, :descriptions_with_types
    ]

    @text ||= (PBCorePresenter.instance_methods(false) - ignores)
              .reject { |method| method =~ /\?$/ } # skip booleans
              .map { |method| send(method) } # method -> value
              .select { |x| x } # skip nils
              .flatten # flattens list accessors
              .map { |x| x.respond_to?(:to_a) ? x.to_a : x } # get elements of compounds
              .flatten.uniq.sort
  end

  def build_display_title
    if titles.map(&:first).count('Series') > 1 && titles.map(&:first).count('Episode Number') > 0 && titles.map(&:first).count('Episode') > 0
      titles.select { |title_pair| title_pair.first == 'Episode' }.map(&:last).join('; ')
    elsif titles.map(&:first).count('Episode Number') > 1 && titles.map(&:first).count('Series') == 1 && titles.map(&:first).count('Episode') > 0
      titles.select { |title_pair| title_pair.first == 'Series' || title_pair.first == 'Episode' }.map(&:last).join('; ')
    elsif titles.map(&:first).count('Alternative') > 0 && titles.map(&:first).count == titles.map(&:first).count('Alternative')
      titles.select { |title_pair| title_pair.first == 'Alternative' }.map(&:last).join('; ')
    else
      titles.select { |title_pair| title_pair.first != 'Alternative' }.map(&:last).join('; ')
    end
  end

  def contribs
    @contribs ||=
      # TODO: Cleaner xpath syntax?
      xpaths('/*/pbcoreCreator/creator') +
      xpaths('/*/pbcoreCreator/creator/@affiliation') +
      xpaths('/*/pbcoreContributor/contributor') +
      xpaths('/*/pbcoreContributor/contributor/@affiliation') +
      xpaths('/*/pbcorePublisher/publisher') +
      xpaths('/*/pbcorePublisher/publisher/@affiliation')
  end

  def year
    @year ||= asset_date ? asset_date.gsub(/-\d\d-\d\d/, '') : nil
  end

  def date_for_assetdate_field
    date_val = asset_date
    return unless date_val
    handle_date_string(date_val, 'index')
  end

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
    @img_dimensions ||= (img_src.nil? || FastImage.size(img_src).nil?) ? [300, 225] : FastImage.size(img_src)
  end
end

require 'rexml/document'
require 'rexml/xpath'
require 'solrizer'
require 'fastimage'
require_relative '../../lib/aapb'
require_relative 'exhibit'
require_relative '../../lib/html_scrubber'
require_relative 'xml_backed'
require_relative 'to_mods'
require_relative 'pb_core_instantiation'
require_relative 'pb_core_name_role_affiliation'
require_relative 'organization'
require_relative '../../lib/formatter'

class PBCore # rubocop:disable Metrics/ClassLength
  # rubocop:disable Style/EmptyLineBetweenDefs
  include XmlBacked
  include ToMods
  def descriptions
    @descriptions ||= xpaths('/*/pbcoreDescription').map { |description| HtmlScrubber.scrub(description) }
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
  def contributors
    @contributors ||= REXML::XPath.match(@doc, '/*/pbcoreContributor').map do |rexml|
      PBCoreNameRoleAffiliation.new(rexml)
    end
  end
  def creators
    @creators ||= REXML::XPath.match(@doc, '/*/pbcoreCreator').map do |rexml|
      PBCoreNameRoleAffiliation.new(rexml)
    end
  end
  def publishers
    @publishers ||= REXML::XPath.match(@doc, '/*/pbcorePublisher').map do |rexml|
      PBCoreNameRoleAffiliation.new(rexml)
    end
  end
  def instantiations
    @instantiations ||= REXML::XPath.match(@doc, '/*/pbcoreInstantiation').map do |rexml|
      PBCoreInstantiation.new(rexml)
    end
  end
  def rights_summary
    @rights_summary ||= xpath('/*/pbcoreRightsSummary/rightsSummary')
  rescue NoMatchError
    nil
  end
  def asset_type
    @asset_type ||= xpath('/*/pbcoreAssetType')
  rescue NoMatchError
    nil
  end
  def asset_dates
    @asset_dates ||= pairs_by_type('/*/pbcoreAssetDate', '@dateType')
  end
  def asset_date
    @asset_date ||= xpath('/*/pbcoreAssetDate[1]')
  rescue NoMatchError
    nil
  end
  def titles
    @titles ||= pairs_by_type('/*/pbcoreTitle', '@titleType')
  end
  def title
    @title ||= titles.map(&:last).join('; ')
  end
  def exhibits
    @exhibits ||= Exhibit.find_all_by_item_id(id)
  end
  def id
    # Solr IDs need to have "cpb-aacip_" instead of "cpb_aacip/" for proper lookup in Solr.
    # Some IDs (e.g. Mississippi) may have "cpb-aacip-", but that's OK.
    # TODO: https://github.com/WGBH/AAPB2/issues/870
    @id ||= xpath('/*/pbcoreIdentifier[@source="http://americanarchiveinventory.org"]').gsub('cpb-aacip/', 'cpb-aacip_')
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
  def media_srcs
    @media_srcs ||= (1..ci_ids.count).map { |part| "/media/#{id}?part=#{part}" }
  end
  CAPTIONS_ANNOTATION = 'Captions URL'.freeze
  def captions_src
    @captions_src ||= xpath("/*/pbcoreAnnotation[@annotationType='#{CAPTIONS_ANNOTATION}']")
  rescue NoMatchError
    nil
  end

  def img_src
    @img_src ||=
      case [media_type, digitized?]
      when [MOVING_IMAGE, true]
        # TODO: Move ID cleaning into Cleaner: https://github.com/WGBH/AAPB2/issues/870
        # Mississippi IDs have dashes, but they cannot for image URLs on S3. All S3 image URLs use "cpb-aacip_".
        "#{AAPB::S3_BASE}/thumbnail/#{id.gsub(/cpb-aacip-/, 'cpb-aacip_')}.jpg"
      when [MOVING_IMAGE, false]
        '/thumbs/video-not-digitized.jpg'
      when [SOUND, true]
        '/thumbs/audio-digitized.jpg'
      when [SOUND, false]
        '/thumbs/audio-not-digitized.jpg'
      when [OTHER, true]
        '/thumbs/other.jpg'
      when [OTHER, false]
        '/thumbs/other.jpg'
      end
    # NOTE: ToMods assumes path-only URLs are locals not to be shared with DPLA.
    # If these got moved to S3, that would need to change.
  end
  def img_height
    @img_height = FastImage.size(img_src)[1]
  end

  def img_width
    @img_width = FastImage.size(img_src)[0]
  end
  def organization_pbcore_name
    @organization_pbcore_name ||= xpath('/*/pbcoreAnnotation[@annotationType="organization"]')
  end
  def organization
    @organization ||= Organization.find_by_pbcore_name(organization_pbcore_name) ||
                      raise("Unrecognized organization_pbcore_name '#{organization_pbcore_name}'")
  end
  def outside_url
    @outside_url ||= begin
      xpath('/*/pbcoreAnnotation[@annotationType="Outside URL"]').tap do |_url|
        raise('If there is an Outside URL, the record must be explicitly public') unless public?
      end
    end
  rescue NoMatchError
    nil
  end
  def reference_urls
    # These only provide extra information. We aren't saying there is media on the far side,
    # so this has no interaction with access_level, unlike outside_url.
    @reference_urls ||= begin
      xpaths('/*/pbcoreAnnotation[@annotationType="External Reference URL"]')
    end
  rescue NoMatchError
    nil
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
    @duration ||= begin
      xpath('/*/pbcoreInstantiation/instantiationGenerations[text()="Proxy"]/../instantiationDuration')
    rescue
      xpaths('/*/pbcoreInstantiation/instantiationDuration').first
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

  # rubocop:enable Style/EmptyLineBetweenDefs

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

    doc_with_caption_flag = @doc.deep_clone
    # perhaps paranoid, but I don't want this method to have side effects.

    caption_response = Net::HTTP.get_response(URI.parse(PBCore.srt_url(id)))
    if caption_response.code == '200'
      pre_existing = REXML::XPath.match(doc_with_caption_flag, "//pbcoreAnnotation[@annotationType='#{CAPTIONS_ANNOTATION}']").first
      pre_existing.parent.elements.delete(pre_existing) if pre_existing
      caption_body = caption_response.body.gsub(/[^[:print:][\n]&&[^ ]]+/, ' ')
      # "\n" is not in the [:print:] class, but it should be preserved.
      # "&&" is intersection: we also want to match " ",
      # so that control-chars + spaces collapse to a single space.
      REXML::XPath.match(doc_with_caption_flag, '/*/pbcoreInstantiation').last.next_sibling.next_sibling =
        REXML::Element.new('pbcoreAnnotation').tap do |el|
          el.add_attribute('annotationType', CAPTIONS_ANNOTATION)
          el.add_text(PBCore.srt_url(id))
        end
    end

    {
      'id' => id,
      'xml' => Formatter.instance.format(doc_with_caption_flag),

      # constrained searches:
      'text' => text + [caption_body].select { |optional| optional },
      'titles' => titles.map(&:last),
      'contribs' => contribs,

      # sort:
      'title' => title,

      # sort and facet:
      'year' => year,

      # facets:
      'exhibits' => exhibits.map(&:path),
      'media_type' => media_type == OTHER ? nil : media_type,
      'genres' => genres,
      'topics' => topics,
      'asset_type' => asset_type,
      'organization' => organization.facet,
      'state' => organization.state,
      'access_types' => access_types
    }.merge(
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
    ignores = [:text, :to_solr, :contribs, :img_src, :media_srcs, :captions_src,
               :rights_code, :access_level, :access_types,
               :organization_pbcore_name, # internal string; not in UI
               :title, :ci_ids, :instantiations,
               :outside_url, :reference_urls, :exhibits]
    @text ||= (PBCore.instance_methods(false) - ignores)
              .reject { |method| method =~ /\?$/ } # skip booleans
              .map { |method| send(method) } # method -> value
              .select { |x| x } # skip nils
              .flatten # flattens list accessors
              .map { |x| x.respond_to?(:to_a) ? x.to_a : x } # get elements of compounds
              .flatten.uniq.sort
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
end

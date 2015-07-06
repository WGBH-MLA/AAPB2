require 'rexml/document'
require 'rexml/xpath'
require 'solrizer'
require_relative 'exhibit'
require_relative '../../lib/html_scrubber'

require_relative 'organization'

class PBCore # rubocop:disable Metrics/ClassLength
  # rubocop:disable Style/EmptyLineBetweenDefs
  def initialize(xml)
    @xml = xml
    @doc = REXML::Document.new xml
  end
  def descriptions
    @descriptions ||= xpaths('/*/pbcoreDescription').map { |description| HtmlScrubber.scrub(description) }
  end
  def genres
    @genres ||= xpaths('/*/pbcoreGenre')
  end
  def subjects
    @subjects ||= xpaths('/*/pbcoreSubject')
  end
  def contributors
    @contributors ||= REXML::XPath.match(@doc, '/*/pbcoreContributor').map do|rexml|
      NameRoleAffiliation.new(rexml)
    end
  end
  def creators
    @creators ||= REXML::XPath.match(@doc, '/*/pbcoreCreator').map do|rexml|
      NameRoleAffiliation.new(rexml)
    end
  end
  def publishers
    @publishers ||= REXML::XPath.match(@doc, '/*/pbcorePublisher').map do|rexml|
      NameRoleAffiliation.new(rexml)
    end
  end
  def instantiations
    @instantiations ||= REXML::XPath.match(@doc, '/*/pbcoreInstantiation').map do|rexml|
      Instantiation.new(rexml)
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
  def titles_sort
    @titles_sort ||= titles.reverse.map { |pair| pair.last }.join(' -- ')
  end
  def titles
    @titles ||= pairs_by_type('/*/pbcoreTitle', '@titleType')
  end
  def title
    @title ||= xpaths('/*/pbcoreTitle[@titleType!="Episode Number"]').first ||
               xpaths('/*/pbcoreTitle').first # There are records that only have "Episode Number"
  end
  def exhibits
    @exhibits ||= Exhibit.find_by_item_id(id).map { |exhibit| exhibit.name }
  end
  def id
    @id ||= xpath('/*/pbcoreIdentifier[@source="http://americanarchiveinventory.org"]').tr('/_', '_/')
    # AAPB IDs, frustratingly, include slashes. We don't expect to see underscore,
    # so swap these two for a loss-less mapping. May revisit.
  end
  SONY_CI = 'Sony Ci'
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
  def img_src # rubocop:disable CyclomaticComplexity
    @img_src ||=
      case [media_type, digitized?]
      when [MOVING_IMAGE, true]
        "http://mlamedia01.wgbh.org/aapb/thumbnail/#{id}.jpg"
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
  end
  def organization_pbcore_name
    @organization_pbcore_name ||= xpath('/*/pbcoreAnnotation[@annotationType="organization"]')
  end
  def organization
    @organization ||= Organization.find_by_pbcore_name(organization_pbcore_name) ||
                      fail("Unrecognized organization_pbcore_name '#{organization_pbcore_name}'")
  end
  def rights_code
    @rights_code ||= xpath('/*/pbcoreRightsSummary/rightsEmbedded/AAPB_RIGHTS_CODE')
  end
  MOVING_IMAGE = 'Moving Image'
  SOUND = 'Sound'
  OTHER = 'other'
  def media_type
    @media_type ||= begin
      media_types = xpaths('/*/pbcoreInstantiation/instantiationMediaType')
      [MOVING_IMAGE, SOUND, OTHER].each do|type|
        return type if media_types.include? type
      end
      return OTHER if media_types == [] # pbcoreInstantiation is not required, so this is possible
      fail "Unexpected media types: #{media_types.uniq}"
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
  def access_types
    @access_types ||= ['All'].tap do|types|
      types << 'Digitized' if digitized?
      # TODO: distinguish if available off-site
    end
  end

  # rubocop:enable Style/EmptyLineBetweenDefs

  def to_solr
    {
      'id' => id,
      'xml' => @xml,

      # constrained searches:
      'text' => text,
      'titles' => titles.map { |pair| pair.last },
      'contribs' => contribs,

      # sort:
      'title' => titles_sort,

      # sort and facet:
      'year' => year,

      # facets:
      'exhibits' => exhibits,
      'media_type' => media_type == OTHER ? nil : media_type,
      'genres' => genres,
      'asset_type' => asset_type,
      'organization' => organization.facet,
      'access_types' => access_types
    }.merge(
      Hash[
        titles.group_by { |pair| pair[0] }.map do|key, pairs|
          ["#{key.downcase.tr(' ', '_')}_titles", pairs.map { |pair| pair[1] }]
        end
      ]
    )
  end

  class Instantiation
    def initialize(rexml_or_media_type, duration=nil)
      if duration
        @media_type = rexml_or_media_type
        @duration = duration
      else
        @rexml = rexml_or_media_type
      end
    end

    def ==(other)
      self.class == other.class &&
        media_type == other.media_type &&
        duration == other.duration
    end

    def media_type
      @media_type ||= optional('instantiationMediaType')
    end

    def duration
      @duration ||= optional('instantiationDuration')
    end

    def to_a
      [media_type, duration].select { |x| x }
    end

    private

    def optional(xpath)
      match = REXML::XPath.match(@rexml, xpath).first
      match ? match.text : nil
    end
  end

  class NameRoleAffiliation
    def initialize(rexml_or_stem, name=nil, role=nil, affiliation=nil)
      if name
        # for testing only
        @stem = rexml_or_stem
        @name = name
        @role = role
        @affiliation = affiliation
      else
        @rexml = rexml_or_stem
        @stem = @rexml.name.gsub('pbcore', '').downcase
      end
    end

    def ==(other)
      self.class == other.class &&
        stem == other.stem &&
        name == other.name &&
        role == other.role &&
        affiliation == other.affiliation
    end

    attr_reader :stem

    def name
      @name ||= REXML::XPath.match(@rexml, @stem).first.text
    end

    def role
      @role ||= begin
        node = REXML::XPath.match(@rexml, "#{@stem}Role").first
        node ? node.text : nil
      end
    end

    def affiliation
      @affiliation ||= begin
        node = REXML::XPath.match(@rexml, "#{@stem}/@affiliation").first
        node ? node.value : nil
      end
    end

    def to_a
      [name, role, affiliation].select { |x| x }
    end
  end

  private

  class NoMatchError < StandardError
  end

  def xpath(xpath)
    REXML::XPath.match(@doc, xpath).tap do |matches|
      if matches.length != 1
        fail NoMatchError, "Expected 1 match for '#{xpath}'; got #{matches.length}"
      else
        return PBCore.text_from(matches.first)
      end
    end
  end

  def xpaths(xpath)
    REXML::XPath.match(@doc, xpath).map { |node| PBCore.text_from(node) }
  end

  def self.text_from(node)
    ((node.respond_to?('text') ? node.text : node.value) || '').strip
  end

  def pairs_by_type(element_xpath, attribute_xpath)
    REXML::XPath.match(@doc, element_xpath).map do |node|
      key = REXML::XPath.first(node, attribute_xpath)
      [
        key ? key.value : nil,
        node.text
      ]
    end
  end

  def hash_by_type(element_xpath, attribute_xpath)
    Hash[pairs_by_type(element_xpath, attribute_xpath)]
  end

# TODO: If we can just iterate over pairs, we don't need either of these.
#
#  def multi_hash_by_type(element_xpath, attribute_xpath) # Not tested
#    Hash[
#      pairs_by_type(element_xpath, attribute_xpath).group_by{|(key,value)| key}.map{|key,pair_list|
#        [key, pair_list.map{|(key,value)| value}]
#      }
#    ]
#  end

  # These methods are only used by to_solr.

  def text
    ignores = [:text, :to_solr, :contribs, :img_src, :media_srcs, :rights_code, :access_types, :titles_sort, :ci_ids, :instantiations]
    @text ||= (PBCore.instance_methods(false) - ignores)
              .reject { |method| method =~ /\?$/ } # skip booleans
              .map { |method| send(method) } # method -> value
              .select { |x| x } # skip nils
              .flatten # flattens list accessors
              .map { |x| x.respond_to?(:to_a) ? x.to_a : x } # get elements of compounds
              .flatten.uniq
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

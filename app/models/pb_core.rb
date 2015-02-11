require 'rexml/document'
require 'rexml/xpath'
require 'solrizer'

require_relative 'organization'

class PBCore
  def initialize(xml)
    @xml = xml
    @doc = REXML::Document.new xml
  end
  def descriptions
    @descriptions ||= xpaths('/*/pbcoreDescription')
  end
  def genres
    @genres ||= xpaths('/*/pbcoreGenre')
  end
  def subjects
    @subjects ||= xpaths('/*/pbcoreSubject')
  end
  def contributors
    @contributors ||= REXML::XPath.match(@doc, '/*/pbcoreContributor').map{|rexml|
      NameRoleAffiliation.new(rexml)
    }
  end
  def creators
    @creators ||= REXML::XPath.match(@doc, '/*/pbcoreCreator').map{|rexml|
      NameRoleAffiliation.new(rexml)
    }
  end
  def publishers
    @publishers ||= REXML::XPath.match(@doc, '/*/pbcorePublisher').map{|rexml|
      NameRoleAffiliation.new(rexml)
    }
  end
  def instantiations
    @instantiations ||= REXML::XPath.match(@doc, '/*/pbcoreInstantiation').map{|rexml|
      Instantiation.new(rexml)
    }
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
    @asset_dates ||= pairs_by_type('/*/pbcoreAssetDate','@dateType')
  end
  def asset_date
    @asset_date ||= xpath('/*/pbcoreAssetDate[1]')
  rescue NoMatchError
    nil
  end
  def titles
    @titles ||= pairs_by_type('/*/pbcoreTitle','@titleType')
  end
  def title
    @title ||= xpath('/*/pbcoreTitle[1]')
  end
  def id
    @id ||= xpath('/*/pbcoreIdentifier[@source="http://americanarchiveinventory.org"]')
  end
  def ids
    @ids ||= begin
      h = hash_by_type('/*/pbcoreIdentifier','@source') # TODO confirm multi-hash not necessary.
      {'AAPB ID' => h.delete('http://americanarchiveinventory.org')}.merge(h).map{|key,value|[key,value]}
      # Relabel AND put at front of list.
      # Map to pairs for consistency... but building the hash and just throwing it away?
    end
  end
  def ci_id
    @ci_id ||= xpaths('/*/pbcoreIdentifier[@source="Sony Ci"]').first # May not be present.
  end
  def img_src
    # ID may contain a slash, and that's ok.
    # TODO!
    @img_src ||= '/thumbnail-todo.svg' # "https://mlamedia01.wgbh.org/aapb/thumbnail/#{id}.jpg"
  end
  def organization_pbcore_name
    @organization_pbcore_name ||= xpath('/*/pbcoreAnnotation[@annotationType="organization"]')
  end
  def organization
    @organization ||= Organization.find_by_pbcore_name(organization_pbcore_name)
  end
  def rights_code
    @rights_code ||= xpath('/*/pbcoreRightsSummary/rightsEmbedded/AAPB_RIGHTS_CODE')
  end
  def media_type
    @media_type ||= begin
      media_types = xpaths('/*/pbcoreInstantiation/instantiationMediaType')
      ['Moving Image', 'Sound', 'other'].each {|type|
        return type if media_types.include? type
      }
      return 'other' if media_types == [] # pbcoreInstantiation is not required, and injected it seems heavy.
      raise "Unexpected media types: #{media_types.uniq}"
    end
  end
  def digitized
    @digitized ||= xpaths('/*/pbcoreInstantiation/instantiationGenerations').include?('Proxy') # TODO get the right value
  end

  def to_solr
    {
      'id' => id,
      'xml' => @xml,
      
      # constrained searches:
      'text' => text,
      'titles' => titles.map{|key,value| value},
      'contribs' => contribs,
      
      # sort:
      'title' => title,
      
      # sort and facet:
      'year' => year,
      
      # facets:
      'media_type' => media_type,
      'genres' => genres,
      'asset_type' => asset_type,
      'organization' => organization.short_name
    }
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
        @stem = @rexml.name.gsub('pbcore','').downcase
      end
    end
    def ==(other)
      self.class == other.class &&
        stem == other.stem &&
        name == other.name &&
        role == other.role &&
        affiliation == other.affiliation
    end
    def stem
      @stem
    end
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
  end
  
  private

  class NoMatchError < StandardError
  end
  
  def xpath(xpath)
    REXML::XPath.match(@doc, xpath).tap do |matches|
      if matches.length != 1
        raise NoMatchError, "Expected 1 match for '#{xpath}'; got #{matches.length}"
      else
        return PBCore::text_from(matches.first)
      end
    end
  end
  
  def xpaths(xpath)
    REXML::XPath.match(@doc, xpath).map{|node| PBCore::text_from(node)}
  end
  
  def self.text_from(node)
    (node.respond_to?('text') ? node.text : node.value).strip
  end
  
  def pairs_by_type(element_xpath, attribute_xpath)
    REXML::XPath.match(@doc, element_xpath).map { |node|
      key = REXML::XPath.first(node, attribute_xpath)
      [
        key ? key.value : nil,
        node.text
      ]
    }
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
    @text ||= xpaths('/*//*[text()]').map{|s| s.strip}.select{|s| !s.empty?}
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
    @year ||= asset_date ? asset_date.gsub(/-\d\d-\d\d/,'') : nil
  end
  
end

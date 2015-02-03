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
    nil # We want to distinguish an empty string from no value in source data
  end
  def asset_date
    @asset_date ||= xpath('/*/pbcoreAssetDate')
  rescue NoMatchError
    nil
  end
  def titles
    @titles ||= Hash[ # "Hashes enumerate their values in the order that the corresponding keys were inserted."
      REXML::XPath.match(@doc, '/*/pbcoreTitle').map { |node|
        [
          REXML::XPath.first(node,'@titleType').value,
          node.text
        ]
      } 
    ]
  end
  def title
    @title ||= xpath('/*/pbcoreTitle[1]')
    # Cleaner has put them in a good order.
  end
  def id
    @id ||= xpath('/*/pbcoreIdentifier[@source="http://americanarchiveinventory.org"]')
  end
  def ids
    @ids ||= xpaths('/*/pbcoreIdentifier') # TODO: is this used?
  end
  def img_src
    # ID may contain a slash, and that's ok.
    @img_src ||= "https://mlamedia01.wgbh.org/aapb/thumbnail/#{id}.jpg"
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
    # Keep Solr name singular, even if the method is plural:
    # Easier not to need to worry about cardinality.
    {
      'id' => id,
      'xml' => @xml,
      
      # constrained searches:
      'text' => text,
      'title' => titles.values,
      'contrib' => contribs,
      
      # facets:
      'media_type' => media_type,
      'genre' => genres,
      'year' => year,
      'asset_type' => asset_type,
      'organization' => organization.short_name
    }
  end
  
  private
  
  # These methods are only used by to_solr.
  # TODO: see if others could be moved here.
  
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
  
  public
  
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
        node = matches.first
        return node.respond_to?('text') ? node.text : node.value
      end
    end
  end
  def xpaths(xpath)
    REXML::XPath.match(@doc, xpath).map{|node| node.respond_to?('text') ? node.text : node.value}
  end
  
  module Optionally
    def optional(xpath)
      match = REXML::XPath.match(@rexml, xpath).first
      match ? match.text : nil
    end
  end
  
  
  class Instantiation
    include Optionally
    def initialize(rexml)
      @rexml = rexml
    end
    def media_type
      @media_type ||= optional('instantiationMediaType')
    end
    def duration
      @duration ||= optional('instantiationDuration')
    end
  end
  
end

require 'rexml/document'
require 'rexml/xpath'
require 'solrizer'

require_relative 'organization'

class PBCore
  def initialize(xml)
    @xml = xml
    @doc = REXML::Document.new xml
  end
  def text
    @text ||= xpaths('/*//*[text()]').map{|s| s.strip}.select{|s| !s.empty?}
  end
  def descriptions
    @descriptions ||= xpaths('/*/pbcoreDescription')
  end
  def asset_type
    @asset_type ||= xpath('/*/pbcoreAssetType') 
  rescue NoMatchError
    nil # We want to distinguish an empty string from no value in source data
  end
  def asset_date
    @asset_date ||= xpath('/*/pbcoreAssetDate') 
    # TODO figure out formats
    # TODO maybe filter by @dateType?
  rescue NoMatchError
    nil
  end
  def titles
    @titles ||= xpaths('/*/pbcoreTitle')
  end
  def title
    @title ||= begin
      # TODO: If a titleType is repeated, we just pick one arbitrarily.
      titles = Hash[
        REXML::XPath.match(@doc, '/pbcoreDescriptionDocument/pbcoreTitle').map { |node|
          [
            REXML::XPath.first(node,'@titleType').value,
            node.text
          ]
        } 
      ]
      # TODO: get the right order.
      titles['program'] || titles['series'] || titles['other'] || raise("Unexpected title types: #{titles.keys}")
    end
  end
  def genre
    @genre ||= xpaths('/*/pbcoreGenre')
  end
  def id
    @id ||= xpath('/*/pbcoreIdentifier[@source="http://americanarchiveinventory.org"]')
  end
  def ids
    @ids ||= xpaths('/*/pbcoreIdentifier')
  end
  def organization_code
    @organization_code ||= xpath('/*/pbcoreAnnotation[@annotationType="organization"]')
  end
  def organization
    @organization ||= Organization.find_by_pbcore_name(organization_code)
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
      'text' => text,
      'title' => title,
      'xml' => @xml,
      'media_type' => media_type,
      'genre' => genre,
      'asset_date' => asset_date,
      'asset_type' => asset_type,
      'organization_code' => organization_code
    }
  end
  
  private

  class NoMatchError < StandardError
  end
  def xpath(xpath)
    REXML::XPath.match(@doc, xpath).tap do |matches|
      if matches.length != 1
        raise NoMatchError, "Expected 1 match for '#{xpath}'; got #{matches.length}"
      else
        return matches.first.text
      end
    end
  end
  def xpaths(xpath)
    REXML::XPath.match(@doc, xpath).map{|l|l.text}
  end
end

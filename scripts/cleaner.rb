require 'rexml/document'
require 'pry'

class Cleaner
  
  attr_reader :report
  
  def initialize
    # For now, report seems like something that will be used on an ad-hoc basis.
    # Not planning on long-term, stable, tested behavior.
    @report = []
  end
  
  def clean(dirty_xml, name='not given')
    doc = REXML::Document.new(dirty_xml)
    
    # pbcoreIdentifier:
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreIdentifier[not(@source)]').each { |node|
      node.attributes['source'] = 'unknown'
    }
    
    # pbcoreTitle:
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument[not(pbcoreTitle)]').each {
      # If there is a match, it's the root node, so no "node" parameter is needed.
      REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreIdentifier').last.next_sibling =
        REXML::Document.new('<pbcoreTitle titleType="program">unknown</pbcoreTitle>')
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreTitle').each { |node|
      title_type = node.attributes['titleType']
      node.attributes['titleType'] = title_type && ['series','program'].include?(title_type.downcase) ? 
        title_type.downcase : 'other'
    }
    
    # pbcoreRelation:
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreRelation').each { |node|
      Cleaner.swap_children(node) if node.elements[1].name == 'pbcoreRelationIdentifier'
    }
    
    # pbcoreCoverage:
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreCoverage[coverageType[not(node())]]').each { |node|
       Cleaner.delete(node)
    }
    
    # TODO: this is a rare problem: consider adding a check in the XPath?
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreCoverage/coverageType').each { |node|
      node.text = node.text.capitalize
    }
    
    # pbcoreCreator/Contributor/Publisher:
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreCreator[not(creator)]').each { |node|
      Cleaner.delete(node)
    }
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreContributor[not(contributor)]').each { |node|
      Cleaner.delete(node)
    }
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcorePublisher[not(publisher)]').each { |node|
      Cleaner.delete(node)
    }
    
    # pbcoreRightsSummary:
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument[not(pbcoreRightsSummary/rightsEmbedded/AAPB_RIGHTS_CODE)]').each { |node|
      REXML::XPath.match(node, Cleaner.any('pbcore', 
          %w(Description Genre Relation Coverage AudienceLevel AudienceRating Creator Contributor Publisher RightsSummary))
      ).last.next_sibling =
        REXML::Document.new('<pbcoreRightsSummary><rightsEmbedded><AAPB_RIGHTS_CODE>' +
                          'ON_LOCATION_ONLY' +
                          '</AAPB_RIGHTS_CODE></rightsEmbedded></pbcoreRightsSummary>')
    }
    
    # pbcoreInstantiation:
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreInstantiation[not(instantiationIdentifier)]').each { |node|
      node[0,0] = REXML::Element.new('instantiationIdentifier')
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreInstantiation/instantiationIdentifier[not(@source)]').each { |node|
      node.attributes['source'] = 'unknown'
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreInstantiation[not(instantiationLocation)]').each { |node|
      REXML::XPath.match(node, Cleaner.any('instantiation', 
          %w(Identifier Date Dimensions Physical Digital Standard))
      ).last.next_sibling =
        REXML::Element.new('instantiationLocation')
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreInstantiation[not(instantiationMediaType)]').each { |node|
      REXML::XPath.match(node, 'instantiationLocation').last.next_sibling =
        REXML::Element.new('instantiationMediaType')
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreInstantiation/instantiationMediaType[. != "Moving Image" and . != "Sound" and . != "other"]').each { |node|
      node.text='other'
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreInstantiation/instantiationLanguage').each { |node|
      node.text = node.text[0..2].downcase # Rare problem; Works for English, but not for other languages.
      node.parent.elements.delete(node) if node.text !~ /^[a-z]{3}/
    }
    
    # formatting:
    
    formatter = REXML::Formatters::Pretty.new(2)
    formatter.compact = true
    output = []
    formatter.write(doc, output)
    output.join('').gsub(/<\?xml version='1\.0' encoding='UTF-8'\?>\s*/, '')
    # XML declaration seems to be output with trailing space, which makes tests just a bit annoying.
    # Just stripping it should be fine.
  end
  
  private
  
  def self.any(pre, list)
    list.map{|item| pre+item}.join('|')
  end
  
  def self.swap_children(node)
    # Not really happy with this approach.
    id = node.elements[1]
    type = node.elements[2]
    node.elements.delete_all '*'
    node.elements[1] = type
    node.elements[2] = id
  end
  
  def self.delete(node)
    node.parent.elements.delete(node)
  end
  
end

if __FILE__ == $0
  cleaner = Cleaner.new
  ARGV.each do |path|
    dirty_xml = File.read(path)
    puts cleaner.clean(dirty_xml)
  end
end
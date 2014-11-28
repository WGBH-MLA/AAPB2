require 'rexml/document'
require 'pry'

class Cleaner
  
  attr_reader :report
  
  def initialize
    # For now, report seems like something that will be used on an ad-hoc basis.
    # Not planning on long-term, stable, tested behavior.
    @report = []
  end
  
  def clean(dirty_xml)
    doc = REXML::Document.new(dirty_xml)
    
    # pbcoreIdentifier:
    
    Cleaner.match(doc, '/pbcoreIdentifier[not(@source)]') { |node|
      node.attributes['source'] = 'unknown'
    }
    
    # pbcoreTitle:
    
    Cleaner.match(doc, '[not(pbcoreTitle)]') {
      # If there is a match, it's the root node, so no "node" parameter is needed.
      Cleaner.insert_after_match(
        doc,
        '/pbcoreDescriptionDocument/pbcoreIdentifier',
        REXML::Document.new('<pbcoreTitle titleType="program">unknown</pbcoreTitle>')
      )
    }
    
    Cleaner.match(doc, '/pbcoreTitle') { |node|
      title_type = node.attributes['titleType']
      node.attributes['titleType'] = title_type && ['series','program'].include?(title_type.downcase) ? 
        title_type.downcase : 'other'
    }
    
    # pbcoreRelation:
    
    Cleaner.match(doc, '/pbcoreRelation') { |node|
      Cleaner.swap_children(node) if node.elements[1].name == 'pbcoreRelationIdentifier'
    }
    
    # pbcoreCoverage:
    
    Cleaner.match(doc, '/pbcoreCoverage[coverageType[not(node())]]') { |node|
       Cleaner.delete(node)
    }
    
    # TODO: this is a rare problem: consider adding a check in the XPath?
    Cleaner.match(doc, '/pbcoreCoverage/coverageType') { |node|
      node.text = node.text.capitalize
    }
    
    # pbcoreCreator/Contributor/Publisher:
    
    Cleaner.match(doc, '/pbcoreCreator[not(creator)]') { |node|
      Cleaner.delete(node)
    }
    Cleaner.match(doc, '/pbcoreContributor[not(contributor)]') { |node|
      Cleaner.delete(node)
    }
    Cleaner.match(doc, '/pbcorePublisher[not(publisher)]') { |node|
      Cleaner.delete(node)
    }
    
    # pbcoreRightsSummary:
    
    Cleaner.match(doc, '[not(pbcoreRightsSummary/rightsEmbedded/AAPB_RIGHTS_CODE)]') { |node|
      Cleaner.insert_after_match(
        node,
        Cleaner.any('pbcore', %w(Description Genre Relation Coverage AudienceLevel AudienceRating Creator Contributor Publisher RightsSummary)),
        REXML::Document.new('<pbcoreRightsSummary><rightsEmbedded><AAPB_RIGHTS_CODE>' +
                          'ON_LOCATION_ONLY' +
                          '</AAPB_RIGHTS_CODE></rightsEmbedded></pbcoreRightsSummary>')
      )
    }
    
    # pbcoreInstantiation:
    
    Cleaner.match(doc, '/pbcoreInstantiation[not(instantiationIdentifier)]') { |node|
      node[0,0] = REXML::Element.new('instantiationIdentifier')
    }
    
    Cleaner.match(doc, '/pbcoreInstantiation/instantiationIdentifier[not(@source)]') { |node|
      node.attributes['source'] = 'unknown'
    }
    
    Cleaner.match(doc, '/pbcoreInstantiation[not(instantiationLocation)]') { |node|
      Cleaner.insert_after_match(
        node, 
        Cleaner.any('instantiation', %w(Identifier Date Dimensions Physical Digital Standard)),
        REXML::Element.new('instantiationLocation')
      )
    }
    
    Cleaner.match(doc, '/pbcoreInstantiation[not(instantiationMediaType)]') { |node|
      Cleaner.insert_after_match(
        node,
        'instantiationLocation',
        REXML::Element.new('instantiationMediaType')
      )
    }
    
    Cleaner.match(doc, '/pbcoreInstantiation/instantiationMediaType[. != "Moving Image" and . != "Sound" and . != "other"]') { |node|
      node.text='other'
    }
    
    Cleaner.match(doc,'/pbcoreInstantiation/instantiationLanguage') { |node|
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
  
  def self.match(doc, xpath_fragment)
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument'+xpath_fragment).each { |node| yield node }
  end
  
  def self.any(pre, list)
    list.map{|item| pre+item}.join('|')
  end
  
  def self.insert_after_match(doc, xpath, insert)
    REXML::XPath.match(doc, xpath).last.next_sibling = insert
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
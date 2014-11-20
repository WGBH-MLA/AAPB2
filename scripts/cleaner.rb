require 'rexml/document'

class Cleaner
  
  def initialize
    # For now, report seems like something that will be used on an ad-hoc basis.
    # Not planning on long-term, stable, tested behavior.
    @report = []
  end
  
  def clean(dirty_xml, source='not given')
    doc = REXML::Document.new(dirty_xml)
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreCoverage[coverageType[not(node())]]').each { |node|
      # doc.delete_element(node)
      # TODO: That ought to work, but it doesn't: delete_element returns the element deleted,
      # and the above returns nil.
      doc.delete_element('/pbcoreDescriptionDocument/pbcoreCoverage[coverageType[not(node())]]')
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreIdentifier[not(@source)]').each { |node|
      node.attributes['source'] = 'unknown'
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreInstantiation/instantiationIdentifier[not(@source)]').each { |node|
      node.attributes['source'] = 'unknown'
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreTitle').each { |node|
      title_type = node.attributes['titleType']
      node.attributes['titleType'] = title_type.match(/series|program/i) ?
        title_type.downcase : 'other'
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument[not(pbcoreTitle)]').each {
      # If there is a match, it's the root node, so no "node" parameter is needed.
      REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreIdentifier').last.next_sibling =
        REXML::Document.new('<pbcoreTitle titleType="program">unknown</pbcoreTitle>')
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreInstantiation').first.previous_sibling =
      REXML::Document.new('<pbcoreRightsSummary><rightsEmbedded><AAPB_RIGHTS_CODE>' +
                          'ON_LOCATION_ONLY' +
                          '</AAPB_RIGHTS_CODE></rightsEmbedded></pbcoreRightsSummary>')
    
    formatter = REXML::Formatters::Pretty.new(2)
    formatter.compact = true
    output = []
    formatter.write(doc, output)
    output.join('').gsub(/<\?xml version='1\.0' encoding='UTF-8'\?>\s*/, '')
    # XML declaration seems to be output with trailing space, which makes tests just a bit annoying.
    # Just stripping it should be fine.
  end
  
end

if __FILE__ == $0
  cleaner = Cleaner.new
  ARGV.each do |path|
    dirty_xml = File.read(path)
    puts cleaner.clean(dirty_xml)
  end
end
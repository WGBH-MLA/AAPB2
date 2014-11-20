require 'rexml/document'

module Cleaner
  
  def self.clean(dirty_xml)
    doc = REXML::Document.new(dirty_xml)
    
    doc.delete_element('/pbcoreDescriptionDocument/pbcoreCoverage[coverageType[not(node())]]')
    
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
    # XML declaration seems to be output with trailing space. Just stripping it should be fine.
  end
  
end

if __FILE__ == $0
  if ARGV.count != 1
    abort "Expects one argument, not #{ARGV.count}"
  end
  
  dirty_xml = File.read(ARGV[0])
  puts Cleaner.clean(dirty_xml)
end
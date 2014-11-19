require 'rexml/document'

module Cleaner
  
  def self.clean(dirty_xml)
    doc = REXML::Document.new(dirty_xml)
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreIdentifier[not(@source)]').each { |node|
      node.attributes['source'] = 'unknown'
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreInstantiation/instantiationIdentifier[not(@source)]').each { |node|
      node.attributes['source'] = 'unknown'
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreTitle').each { |node|
      node.attributes['titleType'] = node.attributes['titleType'].downcase
    }
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreInstantiation').first.previous_sibling =
      REXML::Document.new('<pbcoreRightsSummary><rightsEmbedded><AAPB_RIGHTS_CODE>' +
                          'ON_LOCATION_ONLY' +
                          '</AAPB_RIGHTS_CODE></rightsEmbedded></pbcoreRightsSummary>')
    
    formatter = REXML::Formatters::Pretty.new(2)
    formatter.compact = true
    output = []
    formatter.write(doc, output)
    output.join('')
  end
  
end

if __FILE__ == $0
  if ARGV.count != 1
    abort "Expects one argument, not #{ARGV.count}"
  end
  
  dirty_xml = File.read(ARGV[0])
  puts Cleaner.clean(dirty_xml)
end
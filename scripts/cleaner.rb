require 'rexml/document'

module Cleaner
  
  def self.clean(dirty_xml)
    doc = REXML::Document.new(dirty_xml)
    
    REXML::XPath.match(doc, '/pbcoreDescriptionDocument/pbcoreTitle').each { |node|
      node.attributes['titleType'] = node.attributes['titleType'].downcase
    }
    
    #formatter = Formatters::Pretty.new(2)
    #formatter.compact = true
    #formatter.write(xml, $stdout)
    doc.to_s
  end
  
end

if __FILE__ == $0
  if ARGV.count != 1
    abort "Expects one argument, not #{ARGV.count}"
  end
  
  dirty_xml = File.read(ARGV[0])
  puts Cleaner.clean(dirty_xml)
end
#require 'rexml/document'

module Cleaner
  
  def self.clean(dirty_xml)
    #doc = Document.new(dirty_xml)
    #doc.root[1,0] = Element.new "pbcoreAssetType" # TODO: default value?
    
    #formatter = Formatters::Pretty.new(2)
    #formatter.compact = true
    #formatter.write(xml, $stdout)
    #doc.to_s
    dirty_xml
  end
end

if __FILE__ == $0
  if ARGV.count != 1
    abort "Expects one argument, not #{ARGV.count}"
  end
  
  dirty_xml = File.read(ARGV[0])
  puts Cleaner.clean(dirty_xml)
end
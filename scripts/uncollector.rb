require 'tmpdir'
require 'rexml/xpath'
require 'rexml/document'

module Uncollector
  def self.uncollect(path)
    # Splits a pbcore collection into a number of separate files in the same directory,
    # and removes the original.
    content = File.read(path)
    doc = REXML::Document.new(content)
    REXML::XPath.match(doc, '/*/*').each_with_index do |el, i|
      File.write("#{path.gsub(/\.xml$/,'')}-#{i}.xml", el)
    end
    File.unlink(path)
  end
end

if __FILE__ == $0
  ARGV.each do |path|
    Uncollector.uncollect(path)
  end
end

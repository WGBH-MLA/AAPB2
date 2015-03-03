require 'rexml/xpath'
require 'rexml/document'

module Uncollector
  def self.uncollect_string(string)
    doc = REXML::Document.new(string)
    REXML::XPath.match(doc, '/*/*').map do |el|
      el.to_s
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts Uncollector.uncollect_string(ARGF.read).join("\n")
  else
    abort 'No args: supply xml through STDIN'
  end
end

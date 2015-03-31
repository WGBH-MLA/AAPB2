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

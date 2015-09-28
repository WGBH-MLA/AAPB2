require 'rexml/document'
require 'singleton'

class Formatter
  include Singleton

  def initialize
    @formatter = REXML::Formatters::Pretty.new(2)
    @formatter.compact = true
  end

  def format(doc)
    output = []
    @formatter.write(doc, output)
    output.join
  end
end

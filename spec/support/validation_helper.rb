require 'rexml/document'

module ValidationHelper
  def expect_fuzzy_xml
    xhtml = page.body
    # Kludge valid HTML5 to make it into valid XML.

    # self-close tags
    xhtml.gsub!(/<((meta|link|img|hr|br)([^>]+[^\/])?)>/, '<\2/>')

    # give values to attributes
    attribute_re = %q{(?:\\s+\\w+\\s*=\\s*(?:"[^"]*"|'[^']*'))}
    xhtml.gsub!(/(<\w+#{attribute_re}*\s+\w+)(#{attribute_re}*\/?>)/, '\1=""\2')

    xhtml.gsub!(/<iframe[^>]+><\/iframe>/, '<!-- iframe was here -->')
    REXML::Document.new(xhtml)
  rescue => e
    numbered = xhtml.split(/\n/).each_with_index.map { |line, i| "#{i}:\t#{line}" }.join("\n")
    raise "XML validation failed: '#{e}'\n#{numbered}"
  end
end

RSpec.configure do |c|
  c.include ValidationHelper
end

require 'rexml/document'

module ValidationHelper  
  
  def expect_fuzzy_xml
    xhtml = page.body
    # Kludges to XML Blacklight's default output
    xhtml.gsub!(/<(meta[^>]+[^\/])>/, '<\1/>') # Add self-closing slashes which BL neglects.
    attribute_re = %q{(?:\\s+\\w+\\s*=\\s*(?:"[^"]*"|'[^']*'))}
    xhtml.gsub!(/(<\w+#{attribute_re}*\s+\w+)(#{attribute_re}*\/?>)/, '\1=""\2') # Validation fails without attribute value.
    REXML::Document.new(xhtml)
  rescue => e
    numbered = xhtml.split(/\n/).each_with_index.map{|line,i| "#{i}:\t#{line}"}.join("\n")
    fail "XML validation failed: '#{e}'\n#{numbered}"
  end
  
end

RSpec.configure do |c|
  c.include ValidationHelper
end
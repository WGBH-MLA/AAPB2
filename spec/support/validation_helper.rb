require 'rexml/document'
require_relative 'link_checker'

module ValidationHelper
  # http://www.w3.org/TR/REC-xml/#NT-NameStartChar
  NAME_START_CHARS = <<END
        : A-Z _ a-z \u{C0}-\u{D6} \u{D8}-\u{F6} \u{F8}-\u{2FF}
        \u{370}-\u{37D} \u{37F}-\u{1FFF} \u{200C}-\u{200D} \u{2070}-\u{218F}
        \u{2C00}-\u{2FEF} \u{3001}-\u{D7FF} \u{F900}-\u{FDCF} \u{FDF0}-\u{FFFD}
        \u{10000}-\u{EFFFF}
END
                     .gsub(/\s/, '')
  NAME_CHARS = "#{NAME_START_CHARS} . 0-9 \u{B7} \u{0300}-\u{036F} \u{203F}-\u{2040} -".gsub(/\s/, '')
  XML_NAME_RE = /[#{NAME_START_CHARS}][#{NAME_CHARS}]*+/ # possessive: do not backtrack to find shorter match
  ATTR_VAL_RE = /#{XML_NAME_RE}\s*=\s*(?:"[^"]*"|'[^']*')/
  MISSING_VAL_RE = /
    (<#{XML_NAME_RE}\s+
      (?:#{ATTR_VAL_RE}\s+)*
      #{XML_NAME_RE})\s*+
    (?!=)
  /x

  def expect_fuzzy_xml(options = {})
    allow_default_title = options.delete(:allow_default_title)

    # Kludge valid HTML5 to make it into valid XML.
    xhtml = page.body
    # self-close tags
    xhtml.gsub!(/<((meta|link|img|hr|br|input)([^>]+[^\/])?)>/, '<\2/>')
    # Escape "&" used in Google Analytics tracking code
    xhtml.gsub!('&', '&amp;')

    # give values to attributes
    while xhtml.gsub!(MISSING_VAL_RE, '\1="FILLER" ')
      # Plain gsub doesn't work because that moves the cursor after each replace.
      # RE lookbehinds don't work because they must be constant length.
    end

    # try to parse as xml
    doc = REXML::Document.new(xhtml)

    title_node = REXML::XPath.match(doc, '/html/head/title').first
    raise 'Page should have title' unless title_node && !title_node.text.empty?
    if !allow_default_title && title_node.text == 'American Archive of Public Broadcasting'
      raise 'Page title should be distinctive'
    end

    raise 'Text should not contain raw <p>' if page.text && page.text.include?('<p>')

    bad_urls = page.all('a').map { |element| element['href'] }.reject do |url|
      LinkChecker.instance.check?(url)
    end
    raise "Bad URLS: #{bad_urls}" unless bad_urls.empty?
  rescue => e
    numbered = xhtml.split(/\n/).each_with_index.map { |line, i| "#{i}:\t#{line}" }.join("\n")
    require('pry');binding.pry
    # raise "XML validation failed: #{e}\n#{e.backtrace.join("\n")}\n#{numbered}"
    raise "XML validation failed: #{e}\n#{e.backtrace.join("\n")}\n"
  end
end

RSpec.configure do |c|
  c.include ValidationHelper
end

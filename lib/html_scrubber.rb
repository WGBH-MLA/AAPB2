class HtmlScrubber
  def self.scrub(dirty)
# .split(/\ {2,}/)
    dirtay = dirty
      .gsub('&nbsp;', ' ')
      .gsub('\\0x0A', '')
      .gsub(/[\ \t\u00A0]+/, ' ')
      .gsub(/<style[^>]*>.*?<\/style>/mi, '')
      .gsub(/\{nmap\}.*?\{\/nmap\}/, '')
      .gsub(/<(w:[\S]+).*?\/\1>/m, '') # MS Word special tags with content
      .gsub(/<(p|br)(\s[^>]*)?\/?>/i, "\n")
      .gsub(/<[^>]+>/, '')
      .gsub('\\0x0A', '')
      .gsub(/\?\?\w+/, '')
      .gsub(/\bimg\b/i, '')
      .gsub(/float: \w+/, '')
      .gsub(' ;', '')
      .gsub(/\d+(pt|px|em)/, '')
      


    # strip at ends of lines, then replace consecutive whitespace w/ 1 space
    ActionView::Base.full_sanitizer.sanitize(CGI.unescapeHTML(dirtay)).split("\n").map(&:strip).join("\n")

  end
end


    # # dirty.gsub('&nbsp;', ' ')
    # #              .gsub('&quot;', '"')
    #              .gsub(/<style[^>]*>.*?<\/style>/mi, '')
    #              .gsub(/\{nmap\}.*?\{\/nmap\}/, '')
    #              .gsub(/<(w:[\S]+).*?\/\1>/m, '') # MS Word special tags with content
    #              .gsub(/<(p|br)(\s[^>]*)?\/?>/i, "\n")
    #              .gsub(/<[^>]+>/, '')
    #              .gsub('\\0x0A', '')
    #              .gsub(/\?\?\w+/, '')
    #              .gsub(/\bimg\b/i, '')
    #              .gsub(/float: \w+/, '')
    #              .gsub(' ;', '')
    #              .gsub(/\d+(pt|px|em)/, '')

    #   # Nokogiri::HTML.parse

    #              # .gsub("\n", '')



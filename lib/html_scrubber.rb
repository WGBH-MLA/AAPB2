class HtmlScrubber
  def self.scrub(dirty)
    dirtay = dirty.gsub('&nbsp;', ' ')
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
                  .split("\n").map(&:strip).join("\n").strip

    # strip at ends of lines, then replace consecutive whitespace w/ 1 space
    if dirtay =~ /\/\w+/
      # Angle-brackets stripped, so be more aggressive
      dirtay = dirtay.gsub(/\w+=\S+/, ' ')
    end

    dirtay = dirtay.gsub(/[ \t]+/, ' ')
                   .gsub(/\n( ?\n)+/, "\n")
                   .gsub(/^\s+|\s+$/, '')

    ActionView::Base.full_sanitizer.sanitize(CGI.unescapeHTML(dirtay))
  end
end

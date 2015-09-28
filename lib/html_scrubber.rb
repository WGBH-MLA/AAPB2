class HtmlScrubber
  def self.scrub(dirty)
    dirty = dirty.gsub('&nbsp;', ' ')
            .gsub('&quot;', '"')
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

    if dirty.match(/\/\w+/)
      # Angle-brackets stripped, so be more aggressive
      dirty = dirty.gsub(/\w+=\S+/, ' ')
    end

    dirty.gsub(/[ \t]+/, ' ')
      .gsub(/\n( ?\n)+/, "\n")
      .gsub(/^\s+|\s+$/, '')
  end
end

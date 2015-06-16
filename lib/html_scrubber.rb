class HtmlScrubber  
  def self.scrub(dirty)
    dirty = dirty.gsub('&nbsp;', ' ')
         .gsub('&quot;', '"')
         .gsub(/<(p|br)(\s[^>]*)?\/?>/i, "\n")
         .gsub(/<[^>]+>/, '')
         .gsub('\\0x0A', '')
    
    if dirty.match(/\/\w+/)
      # Angle-brackets stripped, so more aggressive
      dirty = dirty.gsub(/\w+=\S+/, ' ')
                   .gsub(/\b\/\w+/, '')
    end
    
    dirty = dirty.gsub(/[ \t]+/, ' ')
         .gsub(/\n( ?\n)+/, "\n")
         .gsub(/^\s+|\s+$/, '')
  end
end

class HtmlScrubber  
  def self.scrub(dirty)
    dirty.gsub(/&?nbsp;?/, ' ')
         .gsub(/\s+/, ' ')
  end
end

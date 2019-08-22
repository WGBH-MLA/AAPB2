class HtmlScrubber
  def self.scrub(dirty)
    ActionView::Base.full_sanitizer.sanitize(CGI.unescapeHTML(dirty))
  end
end

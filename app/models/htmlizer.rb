require 'htmlentities'

module Htmlizer
  @@coder = HTMLEntities.new

  def self.to_html(text)
    html = text.split(/\s*\n\s*/).map { |p| "<p>#{@@coder.encode(p, :named, :decimal)}</p>" }.join
    html.gsub(/
        (\[ (?<l_text> [^\]]+) \])?
        \[ (?<link> https?:\/\/[^\]]+) \]
        (\[ (?<r_text> [^\]]+) \])?
      /x, '<a href="\k<link>">\k<l_text>\k<r_text></a>')
  end
end

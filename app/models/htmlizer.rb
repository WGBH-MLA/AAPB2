require 'htmlentities'

module Htmlizer
  
  @@coder = HTMLEntities.new
  
  def self.to_html(text)
    text.split(/\s*\n\s*/).map { |p| "<p>#{@@coder.encode(p, :named, :decimal)}</p>" }.join
  end
  
end
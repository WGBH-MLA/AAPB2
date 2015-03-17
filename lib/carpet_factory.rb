require 'redcarpet'

module CarpetFactory
  @@markdown = Redcarpet::Markdown.new(Redcarpet::Render::XHTML, autolink: true)
  def self.render(md_text)
    return unless md_text
    @@markdown.render(md_text)    
  end
end
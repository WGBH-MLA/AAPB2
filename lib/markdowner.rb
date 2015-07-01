require 'redcarpet'

module Markdowner
  @@markdown = Redcarpet::Markdown.new(Redcarpet::Render::XHTML.new(with_toc_data: true), autolink: true)
  def self.render(md_text)
    return unless md_text
    @@markdown.render(md_text)
  end
  def self.render_file(md_file_name)
    # TODO: cache in production environments?
    render(File.read(md_file_name))
  end
end

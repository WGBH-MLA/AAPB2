require_relative '../../lib/markdowner'
require 'nokogiri'

class Exhibit
  attr_reader :name
  attr_reader :slug
  attr_reader :items
  
  attr_reader :summary_html
  attr_reader :thumbnail_url
  attr_reader :author_html
  attr_reader :author_img_src
  attr_reader :links_html
  attr_reader :body_html
  
  def self.find_by_slug(slug)
    @@exhibits_by_slug[slug]
  end
  
  def self.find_by_name(name)
    @@exhibits_by_name[name]
  end
  
  def self.find_by_item_id(id)
    @@exhibits_by_item_id[id] || []
  end
  
  def self.all
    @@exhibits_by_slug.values
  end

  def ids
    items.keys
  end
  
  private
  
  def self.extract_html(doc, title)
    following_siblings = []
    doc.xpath("//*[text()='#{title}']").first.tap do |header|
      while header.next_element && !header.next_element.name.match(/h\d/) do
        following_siblings.push(header.next_element.remove)
      end
      header.remove
    end
    following_siblings.map { |el| el.to_s }.join
  end

  def initialize(path)
    html = Markdowner.render(File.read(path))
    @slug = File.basename(path, '.md')
    Nokogiri::HTML(html).tap do |doc|
      #binding.pry
      @name = doc.xpath('//h1').first.remove.text
      @thumbnail_url = doc.xpath('//img[1]/@src').first.remove.text
      
      @items = Hash[
        doc.xpath('//a').select { |el| 
          el.attribute('href').to_s.match('^/catalog/.+')
        }.map { |el| 
          [
            el.attribute('href').to_s.gsub('/catalog/', ''),
            el.attribute('title').text
          ]
        }
      ]
      
      @summary_html = Exhibit::extract_html(doc, 'Summary')
      @author_html = Exhibit::extract_html(doc, 'Author')
      @links_html = Exhibit::extract_html(doc, 'Links')
      @body_html = Exhibit::extract_html(doc, 'Description')
      
      # TODO: Should be nothing left after this.
    end
  end

  @@exhibits_by_slug = Hash[
    Dir[Rails.root + 'app/views/exhibits/*.md'].map do |path|
      exhibit = Exhibit.new(path)
      [exhibit.slug, exhibit]
    end
  ]
  
  @@exhibits_by_name = Hash[
    Exhibit.all.map{ |exhibit| [exhibit.name, exhibit] }
  ]
  
  @@exhibits_by_item_id = Hash[
    Exhibit.all.map{ |exhibit| exhibit.ids }.flatten.uniq.map do |id|
      [id, Exhibit.all.select { |exhibit| exhibit.ids.include?(id) } ]
    end
  ]
end
require_relative '../../lib/markdowner'
require 'nokogiri'

class Exhibit
  attr_reader :name
  attr_reader :path
  attr_reader :items
  
  attr_reader :summary_html
  attr_reader :thumbnail_url
  attr_reader :author_html
  attr_reader :author_img_src
  attr_reader :links
  attr_reader :body_html
  attr_reader :children
  attr_reader :ancestors
  
  def self.find_by_path(path)
    @@exhibits_by_path[path]
  end
  
  def self.find_by_item_id(id)
    @@exhibits_by_item_id[id] || []
  end
  
  def self.all
    @@exhibits_by_path.values
  end

  def ids
    items.keys
  end
  
  def add_child(child)
    @children.push(child)
  end
  
  def add_items(items)
    @items.merge(items)
  end
  
  private
  
  def self.extract_html(doc, title)
    following_siblings = []
    doc.xpath("//*[text()='#{title}']").first.tap do |header|
      while header.next_element && !header.next_element.name.match(/h2/) do
        following_siblings.push(header.next_element.remove)
      end
      header.remove
    end
    following_siblings.map { |el| el.to_s }.join
  end
  
  def self.path_from_file_path(file_path)
    file_path.to_s.match(/exhibits\/(.*)\.md/).captures.first
  end
  
  def initialize(file_path)
    @children = []
    
    @path = Exhibit.path_from_file_path(file_path)
    
    @path.split('/').tap do |split|
      @ancestors = (1..split.size-1).to_a.map do |i|
        @@exhibits_by_path[split[0,i].join('/')]
      end
    end
    
    @ancestors.last.add_child(self) if @ancestors && !@ancestors.empty?
    
    Nokogiri::HTML(Markdowner.render(File.read(file_path))).tap do |doc|
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
      
      @ancestors.each do |ancestor|
        ancestor.add_items(@items)
      end
      
      @summary_html = Exhibit::extract_html(doc, 'Summary')
      @author_html = Exhibit::extract_html(doc, 'Author')
      @body_html = Exhibit::extract_html(doc, 'Description')
      
      Exhibit::extract_html(doc, 'Links').tap do |links_html|
        Nokogiri::HTML(links_html).tap do |doc|
          @links = doc.xpath('//a').map { |el| 
            [
              el.text,
              el.attribute('href').to_s
            ]
          }
        end
      end
      
      # TODO: Should be nothing left after this.
    end
  end

  @@exhibits_by_path = {}
  Dir[Rails.root + 'app/views/exhibits/**/*.md'].sort.each do |path|
    # Constructor requires higher-level exhibits to already exist.
    # .md files must come before their contents.
    Exhibit.new(path).tap do |exhibit|
      @@exhibits_by_path[exhibit.path] = exhibit
    end
  end
  
  @@exhibits_by_item_id = Hash[
    Exhibit.all.map{ |exhibit| exhibit.ids }.flatten.uniq.map do |id|
      [id, Exhibit.all.select { |exhibit| exhibit.ids.include?(id) } ]
    end
  ]
end
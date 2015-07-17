require_relative '../../lib/markdowner'
require_relative '../../lib/solr'
require 'nokogiri'

class Exhibit
  attr_reader :name
  attr_reader :path
  attr_reader :facets
  
  attr_reader :summary_html
  attr_reader :thumbnail_url
  attr_reader :author_html
  attr_reader :links
  attr_reader :body_html
  
  def self.exhibit_root
    Rails.root + 'app/views/exhibits'
  end
  
  def self.exhibits_by_path
    @exhibits_by_path ||= 
      Hash[
        Dir[self.exhibit_root + '**/*.md'].sort.map do |path|
          exhibit = self.new(path)
          [exhibit.path, exhibit]
        end
      ]
  end
  
  def self.find_by_path(path)
    self.exhibits_by_path[path] || raise(IndexError.new("'#{path}' is not an exhibit path"))
  end
  
  def self.exhibits_by_item_id
    @exhibits_by_item_id ||=
      Hash[
        self.all.map{ |exhibit| exhibit.ids }.flatten.uniq.map do |id|
          [
            id, 
            self.all.select { |exhibit| exhibit.ids.include?(id) }
          ]
        end
      ]
  end
  
  def self.find_by_item_id(id)
    self.exhibits_by_item_id[id] || []
  end
  
  def self.all
    self.exhibits_by_path.values
  end

  def ids
    items.keys
  end
  
  def ancestors
    @ancestors ||= begin
      split = path.split('/')
      (1..split.size-1).to_a.map do |i|
        self.class.exhibits_by_path[split[0,i].join('/')]
      end
    end
  end
  
  def children
    @children ||= begin
      self.class.exhibits_by_path.select do |other_path, other_exhibit|
        other_path.match(/^#{path}\/[^\/]+$/) # TODO: escape
      end.map do |other_path, other_exhibit|
        other_exhibit
      end
    end
  end
  
  def items
    @immediate_items # TODO: ADD child items
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
    @path = self.class.path_from_file_path(file_path)
    
    @facets = Solr.instance.connect.select(params: {
        q: "exhibits:#{path}", 
        rows: 0, 
        facet: true, 
        'facet.field' => ['genres', 'topics']
      })['facet_counts']['facet_fields']
    
    Nokogiri::HTML(Markdowner.render(File.read(file_path))).tap do |doc|
      @name = doc.xpath('//h1').first.remove.text
      @thumbnail_url = doc.xpath('//img[1]/@src').first.remove.text
      # img element is still there.
      
      @immediate_items = Hash[
        doc.xpath('//a').select { |el| 
          el.attribute('href').to_s.match('^/catalog/.+')
        }.map { |el| 
          [
            el.attribute('href').to_s.gsub('/catalog/', ''),
            (el.attribute('title').text rescue el.text)
          ]
        }
      ]
      
      @summary_html = Exhibit::extract_html(doc, 'Summary')
      @author_html = Exhibit::extract_html(doc, 'Author')
      left = false
      @body_html = Exhibit::extract_html(doc, 'Description')
        .gsub('<img ') do |match|
          left = !left
          "<img class='pull-#{left ? 'left' : 'right'}' "
        end
      
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
      
      doc.text.strip.tap do |extra|
        fail("#{file_path} has extra unused text: '#{extra}'") unless extra == ''
      end
    end
  end

end
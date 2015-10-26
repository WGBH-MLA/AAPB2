require_relative '../../lib/solr'
require 'nokogiri'
require 'cmless'

class Exhibit < Cmless
  ROOT = (Rails.root + 'app/views/exhibits').to_s

  attr_reader :summary_html
  attr_reader :author_html
  attr_reader :main_html
  attr_reader :resources_html

  attr_reader :head_html

  def self.all_top_level
    @all_top_level ||=
      Exhibit.select { |exhibit| !exhibit.path.match(/\//) }
  end

  def self.exhibits_by_item_id
    @exhibits_by_item_id ||=
      Hash[
        Exhibit.map { |exhibit| exhibit.ids }.flatten.uniq.map do |id|
          [
            id,
            Exhibit.select { |exhibit| exhibit.ids.include?(id) }
          ]
        end
      ]
  end  
  
  def self.find_all_by_item_id(id)
    exhibits_by_item_id[id] || []
  end
  
  def self.find_top_by_item_id(id)
    all_top_level.select { |ex| ex.ids.include?(id) }
  end

  def thumbnail_url
    @thumbnail_url ||=
      Nokogiri::HTML(summary_html).xpath('//img[1]/@src').first.text
  end

  def ids
    items.keys
  end
  
  def summary_html
    doc = Nokogiri::HTML(@summary_html)
    doc.at_css('img')['class'] = 'pull-right'
    doc.to_html
  end

  def items
    # TODO: Add the items of the children.
    @items ||= begin
      doc = Nokogiri::HTML(summary_html + main_html + head_html)
      hash = Hash[
        doc.xpath('//a').select do |el|
          el.attribute('href').to_s.match('^/catalog/.+')
        end.map do |el|
          [
            el.attribute('href').to_s.gsub('/catalog/', ''),
            (el.attribute('title').text rescue el.text)
          ]
        end
      ]
      children.each do |child|
        hash.merge!(child.items)
      end
      hash
    end
  end

  def main_formatted
    @main_formatted ||= begin
      left = false
      @main_html.gsub('<img ') do |_match|
        left = !left
        "<img class='pull-#{left ? 'left' : 'right'}' "
      end
    end
  end

  def resources
    @resources ||=
      Nokogiri::HTML(resources_html).xpath('//a').map do |el|
        [
          el.text,
          el.attribute('href').to_s
        ]
      end
  end
end

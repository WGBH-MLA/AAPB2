require_relative '../../lib/solr'
require 'nokogiri'
require 'cmless'

class Exhibit < Cmless
  ROOT = (Rails.root + 'app/views/exhibits').to_s

  attr_reader :summary_html
  attr_reader :extended_html
    
  # TODO remove once exhibits are edited to new format
  attr_reader :author_html
  
  attr_reader :main_html
  attr_reader :resources_html

  attr_reader :cover_html
  attr_reader :gallery_html
  attr_reader :records_html
  attr_reader :authors_html

  attr_reader :head_html

  def self.all_top_level
    @all_top_level ||=
      Exhibit.select { |exhibit| !exhibit.path.match(/\//) }
  end

  def self.exhibits_by_item_id
    @exhibits_by_item_id ||=
      Hash[
        Exhibit.map(&:ids).flatten.uniq.map do |id|
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
    doc = Nokogiri::HTML::DocumentFragment.parse(@summary_html)
    doc.at_css('img').tap { |img| img['class'] = 'pull-right' if img }
    doc.inner_html
  end

  def extended_html
    doc = Nokogiri::HTML::DocumentFragment.parse(@extended_html)
    doc.search('img').each do |image|
      image['class'] = 'pull-right'
    end
    doc.inner_html
  end

  def items
    @items ||= begin

      doc = Nokogiri::HTML(summary_html + extended_html + main_html + head_html)
      hash = Hash[
        doc.xpath('//a').select do |el|
          el.attribute('href').to_s.match('^/catalog/.+')
        end.map do |el|
          [
            el.attribute('href').to_s.gsub('/catalog/', ''),
            (begin
               el.attribute('title').text
             rescue
               el.text
             end)
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

  def main_abbrev
    @main_abbrev ||= begin
      @main_html.gsub(/<img[^>]*>/, '')[0..300]
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
  
  def records
    @records ||=
    begin
      Nokogiri::HTML(records_html).xpath('//li').map { |li| li.text }
    end
  end

  def gallery
    @gallery ||=
    begin

      Nokogiri::HTML(gallery_html).xpath('//li').map do |gallery_item|
 
        type = gallery_item.css('a.type').first.text
        record_link = gallery_item.css('a.link').first
        caption = gallery_item.css('a.caption-text').first
        title = gallery_item.css('a.caption-title').first

        media_info = if type == 'audio' || type == 'video' || type == 'iframe'

          url = gallery_item.css('a.media_url').first.text
          {type: type, url: url}
        else #image

          img = gallery_item.xpath('./img').first
          {type: 'image', url: img[:src], alt: img[:alt], title: img[:title]}
        end

        {
          record_url: record_link['href'],
          record_text: record_link.text,
          title: title.text,
          caption: caption.text,
          media_info: media_info          
        }
          
      end
    end
  end

  def cover
    img = Nokogiri::HTML(cover_html).css('img').first

    %(<img src='#{img['src']}' alt='#{img['alt']}' title='#{img['title']}' class='exhibit-section'>)
  end

  def authors
    @authors ||=
    begin
      Nokogiri::HTML(authors_html).xpath('//li').map { |li| {img_url: li.xpath('./img').first['src'], title: li.css('a.title').first.text, name: li.css('a.name').first.text } }
    end
  end
end

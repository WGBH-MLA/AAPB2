require_relative '../../lib/solr'
require 'nokogiri'
require 'cmless'

class Exhibit < Cmless
  ROOT = (Rails.root + 'app/views/exhibits').to_s

  attr_reader :summary_html
  attr_reader :extended_html
    
  # TODO remove once exhibits are edited to new format
  # attr_reader :author_html
  
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

      img = Nokogiri::HTML(summary_html).xpath('//img[1]/@src').first

      unless img
        Nokogiri::HTML(gallery_html).xpath('//img').first
      end

      unless img
        Nokogiri::HTML(main_html).xpath('//img').first
      end

      img.try(:text) || '<img src="" alt="" title="">'
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
      %(#{@main_html.gsub(/<img[^>]*>/, '')[0..300]}...)
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
        record_link = gallery_item.css('a.record-link').first
        caption = gallery_item.css('a.caption-text').first

        media_info = if type == 'audio' || type == 'video' || type == 'iframe'

          url = gallery_item.css('a.media-url').first.text
          {type: type, url: url}
        else #image

          img = gallery_item.css('img').first
          {type: 'image', url: img[:src], alt: img[:alt], title: img[:title]}
        end

        {
          record_url: record_link['href'],
          source_name: record_link.text,
          # title: title.text,
          caption: caption.text,
          media_info: media_info          
        }
          
      end
    end
  end

  def cover
    section_uri = %(/exhibits/#{path})

    if section_uri.end_with?('notes')
      # learning goals nnooootes
      %(<a href="#{section_uri}"><div class="exhibit-notes">
        <div class="exhibit-color">Resource:</div>
        <div class="">
          <img src="/assets/learning_goals.png" class="icon-med" style="top: -2px; position: relative;">
          Learning Goals
        </div>
      </div></a>)
    elsif section_uri.end_with?('resources')
      # reeeeses notes
      %(<a href="#{section_uri}"><div class="exhibit-notes">
        <div class="exhibit-color">Resource:</div>

        <div class="">
          <img src="/assets/research_notes.png" class="icon-med" style="top: -2px; position: relative;">
          Research Notes
        </div>
      </div></a>)
    else

      bckcolor = "%06x" % (rand(0.2..0.4) * 0xffffff)

      img = Nokogiri::HTML(cover_html).css('img').first
      # <img src='#{img['src']}' alt='#{img['alt']}' title='#{img['title']}' > 
      %(<a style="" href="#{section_uri}">
        <div style="background-image: url('#{img['src']}');" class='four-four-box exhibit-section'>

          <div style="position: absolute; bottom: 0; text-align: center; width: 90%; height:33%; padding: 5%; color: #fff; background-color: ##{bckcolor}; opacity: 0.3;"></div>

          <div style="position: absolute; bottom: 0; text-align: center; width: 90%; height:33%; padding: 5%; color: #fff;">
            #{title}
          </div>
        </div>
      </a>)
    end
  end

  def authors
    @authors ||=
    begin
      Nokogiri::HTML(authors_html).xpath('//li').map { |li| {img_url: li.xpath('./img').first['src'], title: li.css('a.title').first.text, name: li.css('a.name').first.text } }
    end
  end
end

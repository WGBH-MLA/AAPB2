require_relative '../../lib/solr'
require 'nokogiri'
require 'cmless'

class Exhibit < Cmless
  ROOT = (Rails.root + 'app/views/exhibits').to_s

  attr_reader :summary_html
  attr_reader :extended_html

  # TODO: remove once exhibits are edited to new format
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
      begin
        img = Nokogiri::HTML(cover_html).xpath('//img[1]/@src').first
        img = Nokogiri::HTML(summary_html).xpath('//img[1]/@src').first unless img
        img = Nokogiri::HTML(gallery_html).xpath('//img[1]/@src').first unless img
        img = Nokogiri::HTML(main_html).xpath('//img[1]/@src').first unless img
        img.text
      end
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

      doc = Nokogiri::HTML(summary_html + extended_html + main_html + head_html + records_html)
      hash = Hash[
        doc.xpath('//a').select do |el|
          el.attribute('href').to_s.match('^/catalog/.+') || el.attribute('href').to_s.match('^http://americanarchive.org/catalog/.+')
        end.map do |el|
          [
            el.attribute('href').to_s.gsub('http://americanarchive.org', '').gsub('/catalog/', ''),
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

  def resources
    @resources ||=
      begin
        Nokogiri::HTML(resources_html).xpath('//a').map do |el|
          [
            el.text,
            el.attribute('href').to_s
          ]
        end
      end
  end

  def records
    @records ||=
      begin
        Nokogiri::HTML(records_html).xpath('//li').map(&:text)
      end
  end

  def gallery
    @gallery ||=
      begin
        Nokogiri::HTML(gallery_html).xpath('//li').map do |gallery_item|
          type = gallery_item.css('a.type').first.text
          credit_link = gallery_item.css('a.credit-link').first
          caption = gallery_item.css('a.caption-text').first

          asset_link = gallery_item.css('a.asset-url').first
          asset_url = asset_link['href'] if asset_link && asset_link['href']

          media_info = if type == 'audio' || type == 'video' || type == 'iframe'

                         url = gallery_item.css('a.media-url').first.text
                         { type: type, url: url }
                       else # image

                         img = gallery_item.css('img').first
                         { type: 'image', url: img[:src], alt: img[:alt], title: img[:title] }
                       end
          {
            credit_url: credit_link['href'],
            source_text: credit_link.text,
            caption: caption.text,
            media_info: media_info,
            asset_url: asset_url
          }
        end
      end
  end

  def cover
    section_uri = %(/exhibits/#{path})

    if section_uri.end_with?('learning-goals')
      # learning goals nnooootes
      %(<div class='exhibit-notes'>
        <div class='#{subsection? ? 'exhibit-color-section' : 'exhibit-color'} bold'>Resource:</div>
          <a href='#{section_uri}'><div class=''>
            <img src='https://s3.amazonaws.com/americanarchive.org/exhibits/assets/learning_goals.png' class='icon-med' style='top: -2px; position: relative;'>
            Learning Goals
          </a>
        </div>
      </div>)
    elsif section_uri.end_with?('notes')
      # reeeeses notes
      %(<div class='exhibit-notes'>
        <div class='#{subsection? ? 'exhibit-color-section' : 'exhibit-color'} bold'>Resource:</div>

        <div class=''>
          <a href='#{section_uri}'>
            <img src='https://s3.amazonaws.com/americanarchive.org/exhibits/assets/research_notes.png' class='icon-med' style='top: -2px; position: relative;'>
            Research Notes
          </a>
        </div>
      </div>)
    elsif section_uri.end_with?('timeline')
      # tiiiiiiiime notes
      %(<div class='exhibit-notes'>
        <div class='#{subsection? ? 'exhibit-color-section' : 'exhibit-color'} bold'>Resource:</div>

        <div class=''>
          <a href='#{section_uri}'>
            <img src='https://s3.amazonaws.com/americanarchive.org/exhibits/assets/timeline_button_grey.png' class='icon-med' style='top: -2px; position: relative;'>
            Timeline
          </a>
        </div>
      </div>)

    else
      img = Nokogiri::HTML(cover_html).css('img').first
      %(<a href='#{section_uri}'>
        <div style="background-image: url('#{img['src'] if img}');" class='four-four-box exhibit-section'>

          <div class='exhibit-cover-overlay bg-color-#{%w(purple pink red).sample}'></div>

          <div class='exhibit-cover-text'>
            #{title}
          </div>
        </div>
      </a>)
    end
  end

  def authors
    @authors ||=
      begin
        Nokogiri::HTML(authors_html).xpath('//li').map { |li| { img_url: li.xpath('./img').first['src'], title: li.css('a.title').first.text, name: li.css('a.name').first.text } }
      end
  end

  def top_title
    ancestors.count > 0 ? ancestors.first.title : title
  end

  def top_path
    ancestors.count > 0 ? ancestors.first.path : path
  end

  def subsection?
    parent ? true : false
  end
end

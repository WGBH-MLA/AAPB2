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

  def self.config
    # load config
    @exhibit_config ||= YAML.load_file(Rails.root + 'config/exhibits.yml')
  end

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

  def config
    @config ||= begin
      global_config = Exhibit.config
      config = global_config
      if global_config[ top_path ]

        # take custom config for this exhibit
        config = global_config[top_path].clone

        global_config.each do |key, value|
          # drop in global config option for anything undefined
          config[key] = global_config[key].clone if (global_config[key] && !config[key])
        end

        # fill in default values for any unset config options
        if !config[:preview]
          # meta tags
          config[:preview] = {
            title: title,
            description: ActionView::Base.full_sanitizer.sanitize(summary_html).gsub(/["']/, ''),
            image: thumbnail_url
          }
        end
      end

      config
    end
  end

  def full_path
    "/exhibits/" + path
  end

  def new_tab
    false
  end

  def meta_tags
    %(
      <meta property="og:title" content="#{config[:preview][:title]} | American Archive of Public Broadcasting" />
      <meta property="og:description" content="#{config[:preview][:description]}" />

      <meta property="og:image" content="#{config[:preview][:image]}" />
      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:site" content="@amarchivepub" />
    )
  end

  def section_hash
    # refer to sections by title rather than cmless array 
    @section_hash ||= begin
      h = {}
      subsections.each {|c| h[c.path] = c }
      h
    end
  end

  def sections
    if config["sections"]
      config["sections"].map {|section_path| section_hash[section_path] }
    else
      subsections.reject {|c| c.title.end_with?("Notes") || c.title.end_with?("Resources") }.sort_by {|c| c.title }
    end
  end

  def subsections
    children.present? ? children : ancestors.first.children
  end

  def notes_cover
    @notes_cover ||= section_hash["#{top_path}/notes"]&.cover&.to_s&.html_safe
  end

  def resources_cover
    @resources_cover ||= section_hash["#{top_path}/resources"]&.cover&.to_s&.html_safe
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
          el.attribute('href').to_s.match('^/catalog/.+') || el.attribute('href').to_s.match(/^.+\/\/americanarchive.org\/catalog\/.+/)
        end.map do |el|
          [
            # remove non guid parts of links, and strip #start_time stuff from end of URL
            el.attribute('href').to_s.gsub(/^.+\/\/americanarchive.org/, '').gsub('/catalog/', '').gsub(/\?.*/, ""),
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
        # take the html that was markdown and is now html and turn each li into a hash so it can be turned back into html in the template render
        Nokogiri::HTML(gallery_html).xpath('//li').map do |gallery_item|
          type = gallery_item.css('a.type').first.text
          credit_link = gallery_item.css('a.credit-link').first
          credit_url = credit_link['href'] if credit_link
          credit_text = credit_link.text if credit_link

          caption = gallery_item.css('a.caption-text').first

          asset_link = gallery_item.css('a.asset-url').first
          asset_url = asset_link['href'] if asset_link && asset_link['href']

          media_info = if type == 'audio' || type == 'video' || type == 'iframe'

                         url = gallery_item.css('a.media-url').first['href']
                         { type: type, url: url }
                       else # image

                         img = gallery_item.css('img').first
                         { type: 'image', url: img[:src], alt: img[:alt], title: img[:title] }
                       end
          {
            credit_url: credit_url,
            source_text: credit_text,
            caption: caption.text,
            media_info: media_info,
            asset_url: asset_url
          }
        end
      end
  end

  def uri
    %(/exhibits/#{path})
  end

  def cover
    if uri.end_with?('learning-goals')
      # learning goals nnooootes
      %(<div class='exhibit-notes'>
        <div class='#{subsection? ? 'exhibit-color-section' : 'exhibit-color'} bold'>Resource:</div>
          <a href='#{uri}'><div class=''>
            <img src='https://s3.amazonaws.com/americanarchive.org/exhibits/assets/learning_goals.png' class='icon-med' style='top: -2px; position: relative;'>
            Learning Goals
          </a>
        </div>
      </div>)
    elsif uri.end_with?('notes')
      # reeeeses notes
      %(<div class='exhibit-notes'>
        <div class='#{subsection? ? 'exhibit-color-section' : 'exhibit-color'} bold'>Resource:</div>

        <div class=''>
          <a href='#{uri}'>
            <img src='https://s3.amazonaws.com/americanarchive.org/exhibits/assets/research_notes.png' class='icon-med' style='top: -2px; position: relative;'>
            Research Notes
          </a>
        </div>
      </div>)
    elsif uri.end_with?('timeline')
      # tiiiiiiiime notes
      %(<div class='exhibit-notes'>
        <div class='#{subsection? ? 'exhibit-color-section' : 'exhibit-color'} bold'>Resource:</div>

        <div class=''>
          <a href='#{uri}'>
            <img src='https://s3.amazonaws.com/americanarchive.org/exhibits/assets/timeline_button_grey.png' class='icon-med' style='top: -2px; position: relative;'>
            Timeline
          </a>
        </div>
      </div>)

    else
      img = Nokogiri::HTML(cover_html).css('img').first
      %(<a href='#{uri}'>
        <div style="background-image: url('#{img['src'] if img}');" class='four-four-box exhibit-section'>

          <div class='exhibit-cover-overlay bg-color-#{%w(purple pink red).sample}'></div>

          <div class='exhibit-cover-text'>
            #{title}
          </div>
        </div>
      </a>)
    end.to_s.html_safe
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

require_relative '../../lib/solr'
require 'nokogiri'
require 'cmless'

class EducatorResource < Cmless
  ROOT = (Rails.root + 'app/views/educator_resources').to_s

  attr_reader :head_html
  # avoid by using toplevel/child as container vs clip
  # attr_reader :type_html

  attr_reader :introduction_html
  attr_reader :cover_html
  attr_reader :thumbnail_html
  attr_reader :citation_html

  attr_reader :author_html
  attr_reader :subjects_html
  attr_reader :teachingtips_html
  attr_reader :additionalresources_html
  attr_reader :pdflink_html
  attr_reader :guid_html 
  attr_reader :cliptime_html

  def self.all_resource_sets
    @all_resource_sets ||=
      EducatorResource.select { |resource| !resource.path.match(%r{\/}) }
  end

  def is_source_set?
    path.exclude?("/")
  end

  def is_resource?
    path.include?("/")
  end

  def resources
    # just a little suga for clarity
    children
  end

  def other_resources
    @other_resources ||= parent.children.reject {|resource| !resource.is_resource? || resource.title == title}
  end

  def top_title
    ancestors.count > 0 ? ancestors.first.title : title
  end

  # required for both
  def introduction_html
    doc = Nokogiri::HTML::DocumentFragment.parse(@introduction_html)
    doc.inner_html.html_safe
  end
  
  def cover_img
    Nokogiri::HTML(cover_html).css('img').first.to_s.html_safe
  end

  def thumbnail_url
    @thumbnail_url ||=
      Nokogiri::HTML(thumbnail_html).xpath('//img[1]/@src').first.text
  end

  def citation_html
    doc = Nokogiri::HTML::DocumentFragment.parse(@citation_html)
    doc.inner_html.html_safe
  end

  def pdf_link
    Nokogiri::HTML(@pdflink_html).text
  end
  
  def clip_start
    # cliptime in format START,END
    @clip_start ||= Nokogiri::HTML(@cliptime_html).text.split(",")[0]
  end

  def clip_end
    @clip_end ||= Nokogiri::HTML(@cliptime_html).text.split(",")[1]
  end

  # container only
  def author
    Nokogiri::HTML(@author_html).inner_html.to_s.html_safe
  end

  def subjects
    Nokogiri::HTML(@subjects_html).inner_html.to_s.html_safe
  end

  def teachingtips_html
    doc = Nokogiri::HTML::DocumentFragment.parse(@teachingtips_html)
    doc.inner_html.to_s.html_safe
  end

  def additional_resources
    doc = Nokogiri::HTML(@additionalresources_html).xpath('//li').map(&:to_s).map(&:html_safe)
  end

  # clip/resource only
  def guid
    ele = Nokogiri::HTML(@guid_html).xpath('//p').first
    ele.text if ele
  end
end

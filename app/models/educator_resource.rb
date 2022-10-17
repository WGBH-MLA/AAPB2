require_relative '../../lib/solr'
require 'nokogiri'
require 'cmless'

class EducatorResource < Cmless
  ROOT = (Rails.root + 'app/views/educator_resources').to_s

  attr_reader :head_html
  # avoid by using toplevel/child as container vs clip
  # attr_reader :type_html

  attr_reader :cover_html
  attr_reader :introduction_html
  attr_reader :teachingtips_html
  attr_reader :additional_resources_html
  attr_reader :citation_html
  attr_reader :thumbnail_html

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

  def top_title
    ancestors.count > 0 ? ancestors.first.title : title
  end

  def cover_img
    Nokogiri::HTML(cover_html).css('img').first.to_s.html_safe
  end
  
  def thumbnail_url
    @thumbnail_url ||=
      Nokogiri::HTML(thumbnail_html).xpath('//img[1]/@src').first.text
  end

  def introduction_html
    doc = Nokogiri::HTML::DocumentFragment.parse(@introduction_html)
    doc.inner_html
  end

  def teachingtips_html
    doc = Nokogiri::HTML::DocumentFragment.parse(@teachingtips_html)
    doc.inner_html
  end

  def additional_resources_html
    doc = Nokogiri::HTML::DocumentFragment.parse(@additional_resources_html)
    doc.inner_html
  end

  def citation_html
    doc = Nokogiri::HTML::DocumentFragment.parse(@citation_html)
    doc.inner_html
  end  
end

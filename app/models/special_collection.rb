require_relative '../../lib/solr'
require 'nokogiri'
require 'cmless'

class SpecialCollection < Cmless
  ROOT = (Rails.root + 'app/views/special_collections').to_s

  attr_reader :thumbnail_html
  attr_reader :collection_html
  attr_reader :producer_html
  attr_reader :resources_html
  attr_reader :featured_html
  attr_reader :funders_html
  attr_reader :help_html

  attr_reader :head_html

  def self.all_top_level
    @all_top_level ||=
      SpecialCollection.select { |collection| !collection.path.match(%r{\//}) }
  end

  def thumbnail_url
    @thumbnail_url ||=
      Nokogiri::HTML(thumbnail_html).xpath('//img[1]/@src').first.text
  end

  def collection_html
    doc = Nokogiri::HTML::DocumentFragment.parse(@collection_html)
    doc.inner_html
  end

  def producer_html
    doc = Nokogiri::HTML::DocumentFragment.parse(@producer_html)
    doc.search('img').each do |image|
      image['class'] = 'pull-right'
    end
    doc.inner_html
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

  def featured_items
    @featured_items ||=
      Nokogiri::HTML(featured_html).xpath('//a').map do |el|
        [
          el.children.first.attributes['alt'].value,
          el.attributes.first[1].value,
          el.children.first.attributes.first[1].value
        ]
      end
  end

  def funders
    @funders ||=
      Nokogiri::HTML(funders_html).xpath('//li').map do |el|
        [
          el.elements[0].children[0].attributes['src'].value,
          el.elements[0].children[0].attributes['alt'].value,
          el.elements[0]['href'],
          el.text.gsub("\n ", '')
        ]
      end
  end

  def help_html
    doc = Nokogiri::HTML::DocumentFragment.parse(@help_html)
    doc.inner_html
  end
end

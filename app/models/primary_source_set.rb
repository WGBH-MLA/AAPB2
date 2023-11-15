require_relative '../../lib/solr'
require 'nokogiri'
require 'cmless'

class PrimarySourceSet < Cmless
  ROOT = (Rails.root + 'app/views/primary_source_sets').to_s

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
  attr_reader :youmayalsolike_html

  def self.all_resource_sets
    @all_resource_sets ||=
      PrimarySourceSet.select { |resource| !resource.path.match(%r{\/}) }
  end

  def source_set?
    !path.include?("/")
  end

  def resource?
    path.include?("/")
  end

  def resources
    # just a little suga for clarity
    @resources ||= ordered_sources(children)
  end

  def other_resources
    @other_resources ||= ordered_sources(parent.children)
  end

  def ordered_sources(sources)
    sources.reject { |resource| !resource.resource? || resource.title == title }.sort_by(&:order)
  end

  def order
    # 1-blahblah.md -> 1
    path.split("/")[1].split("-")[0].to_i
  end

  def top_title
    ancestors.count > 0 ? ancestors.first.title : title
  end

  def full_path
    "/primary_source_sets/" + path
  end

  # required for both
  def introduction_html
    doc = Nokogiri::HTML::DocumentFragment.parse(@introduction_html)
    doc.inner_html.html_safe
  end

  def cover_img
    Nokogiri::HTML(cover_html).text
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
    @clip_start ||= Nokogiri::HTML(@cliptime_html).text.split(",")[0].to_f
  end

  def clip_end
    @clip_end ||= Nokogiri::HTML(@cliptime_html).text.split(",")[1].to_f
  end

  # container only
  def author
    @author ||= Nokogiri::HTML(@author_html).inner_html.to_s.html_safe
  end

  def subjects
    @subjects ||= Nokogiri::HTML(@subjects_html).inner_html.to_s.html_safe
  end

  def teachingtips_html
    doc = Nokogiri::HTML::DocumentFragment.parse(@teachingtips_html)
    doc.inner_html.to_s.html_safe
  end

  def additional_resources
    @additional_resources ||= Nokogiri::HTML(@additionalresources_html).xpath('//li').map(&:to_s).map(&:html_safe)
  end

  # clip/resource only
  def guid
    ele = Nokogiri::HTML(@guid_html).xpath('//p').first
    ele.text.delete(" ") if ele
  end

  def you_may_also_like
    @you_may_also_like ||= begin
      Nokogiri::HTML(@youmayalsolike_html).xpath('//li').map { |li| aapb_content_item_block(li.text) }.compact
    end
  end

  private

  def aapb_content_item_block(str)
    type, identifier = str.split(",")

    if type == "record"

      @solr = Solr.instance.connect
      data = @solr.get('select', params: { q: "id:#{ identifier }", fl: 'xml' })
      xml = data['response']['docs'][0]['xml'] if data['response']['numFound'] > 0
      return unless xml
      item = PBCorePresenter.new(xml)
      { path: "/catalog/#{ item.id }", thumbnail_url: item.img_src, title: item.title }
    else
      # exhibit special_collection or primary_source_set
      if type == "exhibit"
        item = Exhibit.find_by_path(identifier)
      elsif type == "special collection"
        item = SpecialCollection.find_by_path(identifier)
      elsif type == "primary source set"
        item = PrimarySourceSet.find_by_path(identifier)
      else
        raise "Unrecognized youmayalsolike item type #{type} from #{str}"
      end

      { path: item.full_path, thumbnail_url: item.thumbnail_url, title: item.title }
    end
  end
end

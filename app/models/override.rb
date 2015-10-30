class Override < Cmless
  ROOT = (Rails.root + 'app/views/override').to_s
  attr_reader :body_html
  def body_html_wrapped
    @body_html_wrapped ||= begin
      noko = Nokogiri::HTML::DocumentFragment.parse(body_html)
      noko.xpath('.//img').each do |img|
        img['class'] = [img['class'], ' pull-left'].join
      end
      noko.to_html
    end
  end
end

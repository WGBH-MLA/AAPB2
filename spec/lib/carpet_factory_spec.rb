require_relative '../../lib/carpet_factory'

describe CarpetFactory do
#  it 'creates named and numeric character entities and p tags' do
#    html = CarpetFactory.render("<A>\r\n• “B”\r\n\t\u2603")
#    expect(html).to eq('<p>&lt;A&gt;</p><p>&bull; &ldquo;B&rdquo;</p><p>&#9731;</p>')
#  end

  describe 'link maker' do
    it 'nil for nil' do
      html = CarpetFactory.render(nil)
      expect(html).to eq(nil)
    end
    
    
    it 'handles paragraph break' do
      html = CarpetFactory.render("a\n\nb")
      expect(html).to eq(%Q{<p>a</p>\n\n<p>b</p>\n})
    end
    
    it 'handles bare url' do
      html = CarpetFactory.render('http://foo.com & www.bar.com')
      expect(html).to eq(%Q{<p><a href="http://foo.com">http://foo.com</a> &amp; <a href="http://www.bar.com">www.bar.com</a></p>\n})
    end
    
    it 'handles simple link' do
      html = CarpetFactory.render('[text](http://link)')
      expect(html).to eq(%Q{<p><a href="http://link">text</a></p>\n})
    end

    it 'handles complex link' do
      html = CarpetFactory.render('foo [text](https://link.com/path.ext?name=value#anchor) bar')
      expect(html).to eq(%Q{<p>foo <a href="https://link.com/path.ext?name=value#anchor">text</a> bar</p>\n})
    end
  end
end

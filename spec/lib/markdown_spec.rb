require_relative '../../lib/markdowner'

describe Markdowner do
#  it 'creates named and numeric character entities and p tags' do
#    html = Markdowner.render("<A>\r\n• “B”\r\n\t\u2603")
#    expect(html).to eq('<p>&lt;A&gt;</p><p>&bull; &ldquo;B&rdquo;</p><p>&#9731;</p>')
#  end

  describe 'link maker' do
    it 'nil for nil' do
      html = Markdowner.render(nil)
      expect(html).to eq(nil)
    end

    it 'handles paragraph break' do
      html = Markdowner.render("a\n\nb")
      expect(html).to eq(%(<p>a</p>

<p>b</p>
))
    end

    it 'handles bare url' do
      html = Markdowner.render('http://foo.com & www.bar.com')
      expect(html).to eq(%(<p><a href="http://foo.com">http://foo.com</a> &amp; <a href="http://www.bar.com">www.bar.com</a></p>
))
    end

    it 'handles simple link' do
      html = Markdowner.render('[text](http://link)')
      expect(html).to eq(%(<p><a href="http://link">text</a></p>
))
    end

    it 'handles complex link' do
      html = Markdowner.render('foo [text](https://link.com/path.ext?name=value#anchor) bar')
      expect(html).to eq(%(<p>foo <a href="https://link.com/path.ext?name=value#anchor">text</a> bar</p>
))
    end
  end
end

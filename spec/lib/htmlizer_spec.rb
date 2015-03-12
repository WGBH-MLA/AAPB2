require_relative '../../lib/htmlizer'

describe Htmlizer do
  it 'creates named and numeric character entities and p tags' do
    html = Htmlizer.to_html("<A>\r\n• “B”\r\n\t\u2603")
    expect(html).to eq('<p>&lt;A&gt;</p><p>&bull; &ldquo;B&rdquo;</p><p>&#9731;</p>')
  end

  describe 'link maker' do
    it 'handles text-link' do
      html = Htmlizer.to_html('[text][http://link]')
      expect(html).to eq('<p><a href="http://link">text</a></p>')
    end

    it 'handles link-text' do
      html = Htmlizer.to_html('foo [https://link.com/path.ext?name=value#anchor][text] bar')
      expect(html).to eq('<p>foo <a href="https://link.com/path.ext?name=value#anchor">text</a> bar</p>')
    end
  end
end

require 'tiny_spec_helper'

describe Htmlizer do
  
  it 'works' do
    html = Htmlizer::to_html("<A>\n• “B”\n\t\u2603")
    expect(html).to eq("<p>&lt;A&gt;</p><p>&bull; &ldquo;B&rdquo;</p><p>&#9731;</p>")
  end

end
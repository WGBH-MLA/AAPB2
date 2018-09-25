require_relative '../../app/models/exhibit'

describe Exhibit do
  describe 'correctly configured' do
    class MockExhibit < Exhibit
      ROOT = (Rails.root + 'spec/fixtures/exhibits').to_s
    end

    exhibit = MockExhibit.find_by_path('parent/child/grandchild')

    assertions = {
      title: 'Grandchild!',
      title_html: 'Grandchild!',
      toc_html: '',
      path: 'parent/child/grandchild',
      ancestors: [
        MockExhibit.find_by_path('parent'),
        MockExhibit.find_by_path('parent/child')],
      parent: MockExhibit.find_by_path('parent/child'),
      children: [
        MockExhibit.find_by_path('parent/child/grandchild/greatgrandchild1'),
        MockExhibit.find_by_path('parent/child/grandchild/greatgrandchild2')],
      items: {
        'cpb-aacip_80-12893j6c' => 'item 1',
        'cpb-aacip_37-31cjt2qs' => 'item 2',
        'cpb-aacip_192-1937pxnq' => 'fuller description' },
      ids: ['cpb-aacip_80-12893j6c', 'cpb-aacip_37-31cjt2qs', 'cpb-aacip_192-1937pxnq'],
      summary_html: "<p><img src=\"http://example.org/image\" alt=\"alt text\" class=\"pull-right\">\nSummary goes here.</p>",
      extended_html: "<p>This section won't show up on search results.</p>",
      thumbnail_url: 'http://example.org/image',
      author_html: '<p>Author goes here.</p>',
      # TODO: authors_html gallery_html, records_html
      gallery_html: "<ul>\n<li><p><a class=\"type\">video</a>\n&lt;!-- media-url for video or audio v --&gt;\n<a class=\"media-url\">/media/cpb-aacip_151-b56d21s06x</a>\n<a class=\"record-link\" href=\"http://www.cpb.org/link1\">First Source name</a>\n<a class=\"caption-text\">This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. </a></p></li>\n<li><p><a class=\"type\">image</a>\n<a class=\"record-link\" href=\"http://www.cpb.org/link1\">Second Source name</a>\n<a class=\"caption-text\">This is the caption text for the second gallery item. This is the caption text for the second gallery item. This is the caption text for the second gallery item. This is the caption text for the second gallery item. This is the caption text for the second gallery item. </a>\n<img title=\"cover title 2\" alt=\"Alt cover 2\" src=\"https://s3.amazonaws.com/americanarchive.org/exhibits/AAPB_Exhibit_Newsmagazines_image3.jpg\"></p></li>\n<li><p><a class=\"type\">image</a>\n<a class=\"record-link\" href=\"http://www.cpb.org/link1\">Source name</a>\n<a class=\"caption-text\">This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. </a>\n<img title=\"cover title 3\" alt=\"Alt cover 3\" src=\"https://s3.amazonaws.com/americanarchive.org/exhibits/AAPB_Exhibit_Newsmagazines_image2.jpg\"></p></li>\n</ul>",


      main_formatted: "<p><a href=\"/catalog/cpb-aacip_80-12893j6c\">item 1</a>\n<a href=\"/catalog/cpb-aacip_37-31cjt2qs\">item 2</a>\n<a href=\"/catalog/cpb-aacip_192-1937pxnq\" title=\"fuller description\">item 3</a></p>",
      head_html: '',
      resources_html: "<ul>\n<li><a href=\"http://loc.gov\">LoC</a></li>\n<li><a href=\"http://wgbh.org\">WGBH</a></li>\n</ul>",
      resources: [['LoC', 'http://loc.gov'], ['WGBH', 'http://wgbh.org']],
      main_html: <<-EOF
<p><a href="/catalog/cpb-aacip_80-12893j6c">item 1</a>
<a href="/catalog/cpb-aacip_37-31cjt2qs">item 2</a>
<a href="/catalog/cpb-aacip_192-1937pxnq" title="fuller description">item 3</a></p>
      EOF
    }

    assertions.each do |method, value|
      it "\##{method} method works" do
        expect(exhibit.send(method)).to eq((begin
                                              value.strip
                                            rescue
                                              value
                                            end))
      end
    end

    it 'tests everthing' do
      expect(assertions.keys.sort)
        .to eq((Exhibit.instance_methods(false) + Cmless.instance_methods(false)).sort)
    end

    describe 'error handling' do
      it 'raises an error for bad paths' do
        expect { MockExhibit.find_by_path('no/such/path') }.to raise_error(Cmless::Error)
      end
    end
  end
end

require_relative '../../app/models/exhibit'
# rubocop:disable LineLength

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
      summary_html: %(<p><img src=\"http://example.org/image\" alt=\"alt text\" class=\"pull-right\">\nSummary goes here.</p>),
      extended_html: %(<p>This section won't show up on search results.</p>),
      thumbnail_url: %(https://s3.amazonaws.com/americanarchive.org/exhibits/AAPB_Exhibit_Newsmagazines_image5.jpg),
      authors_html: %(<ul>\n<li>\n<img class=\"img-circle pull-left\" src=\"https://s3.amazonaws.com/americanarchive.org/exhibits/assets/author2.png\">\n<a class=\"name\">First Author</a>\n<a class=\"title\">Curator Extraordinaire</a>\n</li>\n<li>\n<img class=\"img-circle pull-left\" src=\"https://s3.amazonaws.com/americanarchive.org/exhibits/assets/author.png\">\n<a class=\"name\">Second Author</a>\n<a class=\"title\">Second Banana</a>\n</li>\n</ul>),
      gallery_html: %(<ul>\n<li><p><a class=\"type\">video</a>\n&lt;!-- media-url for video or audio v --&gt;\n<a class=\"media-url\">/media/cpb-aacip_151-b56d21s06x</a>\n<a class=\"credit-link\" href=\"http://www.cpb.org/link1\">First Source name</a>\n<a class=\"caption-text\">This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. </a>\n<a class=\"asset-url\" href=\"http://americanarchive.org/whoo1\"></a></p></li>\n<li><p><a class=\"type\">image</a>\n<a class=\"credit-link\" href=\"http://www.cpb.org/link2\">Second Source name</a>\n<a class=\"caption-text\">This is the caption text for the second gallery item. This is the caption text for the second gallery item. This is the caption text for the second gallery item. This is the caption text for the second gallery item. This is the caption text for the second gallery item. </a>\n<a class=\"asset-url\" href=\"http://americanarchive.org/whoo2\"></a>\n<img title=\"cover title 2\" alt=\"Alt cover 2\" src=\"https://s3.amazonaws.com/americanarchive.org/exhibits/AAPB_Exhibit_Newsmagazines_image3.jpg\"></p></li>\n<li><p><a class=\"type\">image</a>\n<a class=\"credit-link\" href=\"http://www.cpb.org/link3\">Source name</a>\n<a class=\"caption-text\">This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. </a>\n<a class=\"asset-url\" href=\"http://americanarchive.org/whoo3\"></a>\n<img title=\"cover title 3\" alt=\"Alt cover 3\" src=\"https://s3.amazonaws.com/americanarchive.org/exhibits/AAPB_Exhibit_Newsmagazines_image2.jpg\"></p></li>\n</ul>),
      records_html: %(<ul>\n<li>/catalog/cpb-aacip_60-70msbm1d</li>\n<li>/catalog/cpb-aacip_15-9fj29c7n</li>\n<li>/catalog/cpb-aacip_500-9z90dj38</li>\n</ul>),
      records: ['/catalog/cpb-aacip_60-70msbm1d', '/catalog/cpb-aacip_15-9fj29c7n', '/catalog/cpb-aacip_500-9z90dj38'],
      main_formatted: %(<p>Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. \n<a href=\"/catalog/cpb-aacip_80-12893j6c\">item 1</a>\n<a href=\"/catalog/cpb-aacip_37-31cjt2qs\">item 2</a>\n<a href=\"/catalog/cpb-aacip_192-1937pxnq\" title=\"fuller description\">item 3</a></p>),
      head_html: '',
      resources_html: %(<ul>\n<li><a href=\"http://loc.gov\">LoC</a></li>\n<li><a href=\"http://wgbh.org\">WGBH</a></li>\n</ul>),
      resources: [['LoC', 'http://loc.gov'], ['WGBH', 'http://wgbh.org']],
      main_html: %(<p>Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. \n<a href=\"/catalog/cpb-aacip_80-12893j6c\">item 1</a>\n<a href=\"/catalog/cpb-aacip_37-31cjt2qs\">item 2</a>\n<a href=\"/catalog/cpb-aacip_192-1937pxnq\" title=\"fuller description\">item 3</a></p>),
      cover: %(<a href='/exhibits/parent/child/grandchild'>
        <div style="background-image: url('https://s3.amazonaws.com/americanarchive.org/exhibits/AAPB_Exhibit_Newsmagazines_image5.jpg');" class='four-four-box exhibit-section'>

          <div class='exhibit-cover-overlay bg-color-red'></div>

          <div class='exhibit-cover-text'>
            Grandchild!
          </div>
        </div>
      </a>),

      cover_html: %(<p><img title=\"cover title 2\" alt=\"Alt cover 2\" src=\"https://s3.amazonaws.com/americanarchive.org/exhibits/AAPB_Exhibit_Newsmagazines_image5.jpg\"></p>),
      gallery: [{ credit_url: 'http://www.cpb.org/link1',
                  asset_url: 'http://americanarchive.org/whoo1',
                  source_text: 'First Source name',
                  caption:
                   %(This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. ),
                  media_info: { type: 'video', url: '/media/cpb-aacip_151-b56d21s06x' } },
                { credit_url: 'http://www.cpb.org/link2',
                  asset_url: 'http://americanarchive.org/whoo2',
                  source_text: 'Second Source name',
                  caption: 'This is the caption text for the second gallery item. This is the caption text for the second gallery item. This is the caption text for the second gallery item. This is the caption text for the second gallery item. This is the caption text for the second gallery item. ',
                  media_info:
                    { type: 'image',
                      url: 'https://s3.amazonaws.com/americanarchive.org/exhibits/AAPB_Exhibit_Newsmagazines_image3.jpg',
                      alt: 'Alt cover 2',
                      title: 'cover title 2' }
                    },
                { credit_url: 'http://www.cpb.org/link3',
                  asset_url: 'http://americanarchive.org/whoo3',
                  source_text: 'Source name',
                  caption: 'This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. ',
                  media_info:
                    { type: 'image',
                      url: 'https://s3.amazonaws.com/americanarchive.org/exhibits/AAPB_Exhibit_Newsmagazines_image2.jpg',
                      alt: 'Alt cover 3',
                      title: 'cover title 3' } }],

                      # rubocop:disable Style/AlignHash
                      # cant make this happy v
                      authors: [{ img_url: 'https://s3.amazonaws.com/americanarchive.org/exhibits/assets/author2.png',
                                  title: 'Curator Extraordinaire',
                                  name: 'First Author' },
                                { img_url: 'https://s3.amazonaws.com/americanarchive.org/exhibits/assets/author.png',
                                  title: 'Second Banana',
                                  name: 'Second Author' }],
      # rubocop:enable Style/AlignHash
      subsection?: true,
      top_title: 'Parent!',
      top_path: 'parent'
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
# rubocop:enable LineLength

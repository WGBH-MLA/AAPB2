require_relative '../../app/models/exhibit'

describe Exhibit do
  describe 'correctly configured' do
    class MockExhibit < Exhibit
      ROOT = (Rails.root + 'spec/fixtures/exhibits').to_s
    end

    let(:exhibit) { MockExhibit.find_by_path('parent/child/grandchild') }

    describe '.items' do
      it 'returns all the items in the exhibit' do
        expect(exhibit.items).to eq(
          'cpb-aacip_80-12893j6c' => 'item 1',
          'cpb-aacip_37-31cjt2qs' => 'item 2',
          'cpb-aacip_192-1937pxnq' => 'fuller description'
        )
      end
    end

    describe '.ids' do
      it 'returns all the ids of items in the exhibit' do
        expect(exhibit.ids).to eq([
          'cpb-aacip_80-12893j6c', 'cpb-aacip_37-31cjt2qs', 'cpb-aacip_192-1937pxnq'
        ])
      end
    end

    describe '.summary_html' do
      it 'returns the summary' do
        expect(exhibit.summary_html).to eq(%(<p><img src=\"http://example.org/image\" alt=\"alt text\" class=\"pull-right\">\nSummary goes here.</p>))
      end
    end

    describe '.extended_html' do
      it 'returns the extended html' do
        expect(exhibit.extended_html).to eq(%(<p>This section won't show up on search results.</p>))
      end
    end

    describe '.thumbnail_url' do
      it 'returns the thumbnail url' do
        expect(exhibit.thumbnail_url).to eq(%(https://s3.amazonaws.com/americanarchive.org/exhibits/AAPB_Exhibit_Newsmagazines_image5.jpg))
      end
    end

    describe '.authors_html' do
      it 'returns the authors html' do
        expect(exhibit.authors_html).to eq(%(<ul>\n<li>\n<img class=\"img-circle pull-left\" src=\"https://s3.amazonaws.com/americanarchive.org/exhibits/assets/author2.png\">\n<a class=\"name\">First Author</a>\n<a class=\"title\">Curator Extraordinaire</a>\n</li>\n<li>\n<img class=\"img-circle pull-left\" src=\"https://s3.amazonaws.com/americanarchive.org/exhibits/assets/author.png\">\n<a class=\"name\">Second Author</a>\n<a class=\"title\">Second Banana</a>\n</li>\n</ul>))
      end
    end

    describe 'gallery_html' do
      it 'returns the gallery html' do
        expect(exhibit.gallery_html).to eq(%(<ul>\n<li><p><a class=\"type\">video</a>\n&lt;!-- media-url for video or audio v --&gt;\n<a class=\"media-url\">/media/cpb-aacip_151-b56d21s06x</a>\n<a class=\"credit-link\" href=\"http://www.cpb.org/link1\">First Source name</a>\n<a class=\"caption-text\">This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. </a>\n<a class=\"asset-url\" href=\"http://americanarchive.org/whoo1\"></a></p></li>\n<li><p><a class=\"type\">image</a>\n<a class=\"credit-link\" href=\"http://www.cpb.org/link2\">Second Source name</a>\n<a class=\"caption-text\">This is the caption text for the second gallery item. This is the caption text for the second gallery item. This is the caption text for the second gallery item. This is the caption text for the second gallery item. This is the caption text for the second gallery item. </a>\n<a class=\"asset-url\" href=\"http://americanarchive.org/whoo2\"></a>\n<img title=\"cover title 2\" alt=\"Alt cover 2\" src=\"https://s3.amazonaws.com/americanarchive.org/exhibits/AAPB_Exhibit_Newsmagazines_image3.jpg\"></p></li>\n<li><p><a class=\"type\">image</a>\n<a class=\"credit-link\" href=\"http://www.cpb.org/link3\">Source name</a>\n<a class=\"caption-text\">This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. This is the caption text for the first gallery item. </a>\n<a class=\"asset-url\" href=\"http://americanarchive.org/whoo3\"></a>\n<img title=\"cover title 3\" alt=\"Alt cover 3\" src=\"https://s3.amazonaws.com/americanarchive.org/exhibits/AAPB_Exhibit_Newsmagazines_image2.jpg\"></p></li>\n</ul>))
      end
    end

    describe '.records_html' do
      it 'returns the records html' do
        expect(exhibit.records_html).to eq(%(<ul>\n<li>/catalog/cpb-aacip_60-70msbm1d</li>\n<li>/catalog/cpb-aacip_15-9fj29c7n</li>\n<li>/catalog/cpb-aacip_500-9z90dj38</li>\n</ul>))
      end
    end

    describe '.records' do
      it 'returns the records' do
        expect(exhibit.records).to eq(['/catalog/cpb-aacip_60-70msbm1d', '/catalog/cpb-aacip_15-9fj29c7n', '/catalog/cpb-aacip_500-9z90dj38'])
      end
    end

    describe '.main_formatted' do
      it 'returns the main formatted html' do
        expect(exhibit.main_formatted).to eq(%(<p>Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. \n<a href=\"/catalog/cpb-aacip_80-12893j6c\">item 1</a>\n<a href=\"/catalog/cpb-aacip_37-31cjt2qs\">item 2</a>\n<a href=\"/catalog/cpb-aacip_192-1937pxnq\" title=\"fuller description\">item 3</a></p>))
      end
    end

    describe '.resources_html' do
      it 'returns the resources html' do
        expect(exhibit.resources_html).to eq(%(<ul>\n<li><a href=\"http://loc.gov\">LoC</a></li>\n<li><a href=\"http://wgbh.org\">WGBH</a></li>\n</ul>))
      end
    end

    describe '.resources' do
      it 'returns the resources' do
        expect(exhibit.resources).to eq([['LoC', 'http://loc.gov'], ['WGBH', 'http://wgbh.org']])
      end
    end

    describe '.main_html' do
      it 'returns the main html' do
        expect(exhibit.main_html).to eq(%(<p>Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. Description goes here. \n<a href=\"/catalog/cpb-aacip_80-12893j6c\">item 1</a>\n<a href=\"/catalog/cpb-aacip_37-31cjt2qs\">item 2</a>\n<a href=\"/catalog/cpb-aacip_192-1937pxnq\" title=\"fuller description\">item 3</a></p>))
      end
    end

    describe '.cover_html' do
      it 'returns the cover html' do
        expect(exhibit.cover_html).to eq(%(<p><img title=\"cover title 2\" alt=\"Alt cover 2\" src=\"https://s3.amazonaws.com/americanarchive.org/exhibits/AAPB_Exhibit_Newsmagazines_image5.jpg\"></p>))
      end
    end

    describe '.gallery' do
      it 'returns the gallery' do
        expect(exhibit.gallery).to eq([
          { credit_url: 'http://www.cpb.org/link1',
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
                title: 'cover title 3' }
            }
          ])
      end
    end

    describe '.authors' do
      it 'returns the authors' do
        expect(exhibit.authors).to eq([
          { img_url: 'https://s3.amazonaws.com/americanarchive.org/exhibits/assets/author2.png',
            title: 'Curator Extraordinaire',
            name: 'First Author' },
          { img_url: 'https://s3.amazonaws.com/americanarchive.org/exhibits/assets/author.png',
            title: 'Second Banana',
            name: 'Second Author' }
        ])
      end
    end

    describe '.subsection?' do
      it 'returns true if parent' do
        expect(exhibit.subsection?).to eq(true)
      end
    end

    describe '.top_title' do
      it 'returns the top title' do
        expect(exhibit.top_title).to eq('Parent!')
      end
    end

    describe '.top_path' do
      it 'returns the top_path' do
        expect(exhibit.top_path).to eq('parent')
      end
    end

    describe 'error handling' do
      it 'raises an error for bad paths' do
        expect { MockExhibit.find_by_path('no/such/path') }.to raise_error(Cmless::Error)
      end
    end
  end
end

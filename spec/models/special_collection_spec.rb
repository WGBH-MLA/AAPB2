require_relative '../../app/models/special_collection'

describe SpecialCollection do
  describe 'correctly configured' do
    class MockSpecialCollection < SpecialCollection
      ROOT = (Rails.root + 'spec/fixtures/special_collections').to_s
    end

    collection = MockSpecialCollection.find_by_path('test-special-collection')

    describe '.ancestors' do
      # xiting out because this only returns an empty array from the fixture
      xit 'returns the all ancestors for the collection' do
        expect(collection.ancestors).to eq([])
      end
    end

    describe '.parent' do
      # xiting out because this only returns nil from the fixture
      xit 'returns the parent for the collection' do
        expect(collection.parent).to eq(nil)
      end
    end

    describe '.children' do
      # xiting out because this only returns an empty array from the fixture
      xit 'returns the children of the collection' do
        expect(collection.children).to eq([])
      end
    end

    describe '.featured_items' do
      it 'returns the featured items for the collection' do
        expect(collection.featured_items).to eq([
          ['Test Featured Item', '/catalog/cpb-aacip_111-21ghx7d6', 'http://americanarchive.org.s3.amazonaws.com/thumbnail/cpb-aacip_509-2r3nv99t98.jpg'],
          ['Test Featured Item 2', '/catalog/cpb-aacip_111-21ghx7d6', 'http://americanarchive.org.s3.amazonaws.com/thumbnail/cpb-aacip_509-6h4cn6zm21.jpg']
        ])
      end
    end

    describe '.path' do
      it 'returns the path for the collection' do
        expect(collection.path).to eq('test-special-collection')
      end
    end

    describe '.resources' do
      it 'returns the resources for the collection' do
        expect(collection.resources).to eq([
          ['The Civil War on PBS.org', 'http://www.pbs.org/kenburns/civil-war/'],
          ['Restoring The Civil War film', 'http://www.pbs.org/kenburns/civil-war/restoring-film/']
        ])
      end
    end

    describe '.thumbnail_url' do
      it 'returns the src for the collection thumbnail' do
        expect(collection.thumbnail_url).to eq('https://s3.amazonaws.com/americanarchive.org/special-collections/CivilWarKenBurns.jpg')
      end
    end

    describe '.toc_html' do
      # xiting out because this only returns an empty string from the fixture
      xit 'returns the HTML for the table of contents' do
        expect(collection.toc_html).to eq('')
      end
    end

    describe '.funders' do
      it 'returns the funder information for the collection' do
        expect(collection.funders).to eq([
          ['https://s3.amazonaws.com/americanarchive.org/org-logos/neh_logo.jpg', 'NEH', 'https://www.neh.gov/', 'The National Endowment for the Humanities funds stuff like this!']
        ])
      end
    end

    describe '.title' do
      it 'returns the title of the collection' do
        expect(collection.title).to eq('Test Collection')
      end
    end

    describe '.title_html' do
      it 'returns the title HTML for the collection' do
        expect(collection.title_html).to eq('Test Collection')
      end
    end

    describe '.summary_html' do
      it 'returns the summary HTML for the collection' do
        expect(collection.summary_html).to eq('<p>Test Collection Description</p>')
      end
    end

    describe '.terms' do
      it 'returns the terms of the collection' do
        expect(collection.terms).to eq([
          ['Term 1', 'https://www.google.com/'],
          ['Term 2', 'https://www.google.com/']
        ])
      end
    end

    describe '.background_html' do
      it 'returns the background HTML for the collection' do
        expect(collection.background_html).to eq('<p>Test Producer Description</p>')
      end
    end

    describe '.featured_html' do
      it 'returns the featured html for the collection' do
        expect(collection.featured_html).to eq("<p><a href=\"/catalog/cpb-aacip_111-21ghx7d6\"><img src=\"http://americanarchive.org.s3.amazonaws.com/thumbnail/cpb-aacip_509-2r3nv99t98.jpg\" alt=\"Test Featured Item\"></a>\n<a href=\"/catalog/cpb-aacip_111-21ghx7d6\"><img src=\"http://americanarchive.org.s3.amazonaws.com/thumbnail/cpb-aacip_509-6h4cn6zm21.jpg\" alt=\"Test Featured Item 2\"></a></p>")
      end
    end

    describe '.resources_html' do
      it 'returns the resources html for the collection' do
        expect(collection.resources_html).to eq("<ul>\n<li><a href=\"http://www.pbs.org/kenburns/civil-war/\"><em>The Civil War</em> on PBS.org</a></li>\n<li><a href=\"http://www.pbs.org/kenburns/civil-war/restoring-film/\">Restoring <em>The Civil War</em> film</a></li>\n</ul>")
      end
    end

    describe '.funders_html' do
      it 'returns the funders html for the collection' do
        expect(collection.funders_html).to eq("<ul>\n<li>\n<a href=\"https://www.neh.gov/\"><img src=\"https://s3.amazonaws.com/americanarchive.org/org-logos/neh_logo.jpg\" alt=\"NEH\"></a> The National Endowment for the Humanities funds stuff like this!</li>\n</ul>")
      end
    end

    describe '.terms_html' do
      it 'returns the terms html for the collection' do
        expect(collection.terms_html).to eq("<ul>\n<li><a href=\"https://www.google.com/\">Term 1</a></li>\n<li><a href=\"https://www.google.com/\">Term 2</a></li>\n</ul>")
      end
    end

    describe '.thumbnail_html' do
      it 'returns the thumbnail html for the collection' do
        expect(collection.thumbnail_html).to eq("<p><img src=\"https://s3.amazonaws.com/americanarchive.org/special-collections/CivilWarKenBurns.jpg\" alt=\"Test Thumbnail\" title=\"Test Thumbnail\"></p>")
      end
    end

    describe '.help_html' do
      it 'returns the help html for the collection' do
        expect(collection.help_html).to eq('<p>This is the search help text.</p>')
      end
    end

    describe '.timeline_html' do
      it 'returns the timeline html for the collection' do
        expect(collection.timeline_html).to eq("<h3 id=\"the-title-of-the-timeline\">The Title of the Timeline</h3><iframe src=\"https://cdn.knightlab.com/libs/timeline3/latest/embed/index.html?source=1ISfXGK8EEuqCGcONWfekjLZhInxFQyFWwBAl2FbkIxs&amp;font=Default&amp;lang=en&amp;initial_zoom=2&amp;height=650&amp;width=100%\" height=\"650\" width=\"100%\" frameborder=\"0\"></iframe>")
      end
    end

    describe '.timeline_title' do
      it 'returns the timeline title for the collection' do
        expect(collection.timeline_title).to eq('The Title of the Timeline')
      end
    end

    describe '.timeline' do
      it 'returns the timeline for the collection' do
        expect(collection.timeline).to eq("<iframe src=\"https://cdn.knightlab.com/libs/timeline3/latest/embed/index.html?source=1ISfXGK8EEuqCGcONWfekjLZhInxFQyFWwBAl2FbkIxs&amp;font=Default&amp;lang=en&amp;initial_zoom=2&amp;height=650&amp;width=100%\" height=\"650\" width=\"100%\" frameborder=\"0\"></iframe>")
      end
    end

    describe 'error handling' do
      it 'raises an error for bad paths' do
        expect { MockSpecialCollection.find_by_path('no/such/path') }.to raise_error(Cmless::Error)
      end
    end
  end
end

require_relative '../../app/models/special_collection'

describe SpecialCollection do
  describe 'correctly configured' do
    class MockSpecialCollection < SpecialCollection
      ROOT = (Rails.root + 'spec/fixtures/special_collections').to_s
    end

    collection = MockSpecialCollection.find_by_path('test-special-collection')

    assertions = {
      ancestors: [],
      parent: nil,
      children: [],
      head_html: '',
      featured_items: [['Test Featured Item',
                        '/catalog/cpb-aacip_111-21ghx7d6',
                        'http://americanarchive.org.s3.amazonaws.com/thumbnail/cpb-aacip_509-2r3nv99t98.jpg'],
                       ['Test Featured Item 2',
                        '/catalog/cpb-aacip_111-21ghx7d6',
                        'http://americanarchive.org.s3.amazonaws.com/thumbnail/cpb-aacip_509-6h4cn6zm21.jpg']],
      path: 'test-special-collection',
      resources: [['The Civil War on PBS.org',
                   'http://www.pbs.org/kenburns/civil-war/'],
                  ['Restoring The Civil War film',
                   'http://www.pbs.org/kenburns/civil-war/restoring-film/']],
      thumbnail_url: 'https://s3.amazonaws.com/americanarchive.org/special-collections/CivilWarKenBurns.jpg',
      toc_html: '',
      funders: [['https://s3.amazonaws.com/americanarchive.org/org-logos/neh_logo.jpg',
                 'NEH',
                 'https://www.neh.gov/',
                 'The National Endowment for the Humanities funds stuff like this!']],
      title: 'Test Collection',
      title_html: 'Test Collection',
      collection_html: '<p>Test Collection Description</p>',
      producer_html: '<p>Test Producer Description</p>',
      # rubocop:disable LineLength
      featured_html: "<p><a href=\"/catalog/cpb-aacip_111-21ghx7d6\"><img src=\"http://americanarchive.org.s3.amazonaws.com/thumbnail/cpb-aacip_509-2r3nv99t98.jpg\" alt=\"Test Featured Item\"></a>\n<a href=\"/catalog/cpb-aacip_111-21ghx7d6\"><img src=\"http://americanarchive.org.s3.amazonaws.com/thumbnail/cpb-aacip_509-6h4cn6zm21.jpg\" alt=\"Test Featured Item 2\"></a></p>",
      resources_html: "<ul>\n<li><a href=\"http://www.pbs.org/kenburns/civil-war/\"><em>The Civil War</em> on PBS.org</a></li>\n<li><a href=\"http://www.pbs.org/kenburns/civil-war/restoring-film/\">Restoring <em>The Civil War</em> film</a></li>\n</ul>",
      funders_html: "<ul>\n<li>\n<a href=\"https://www.neh.gov/\"><img src=\"https://s3.amazonaws.com/americanarchive.org/org-logos/neh_logo.jpg\" alt=\"NEH\"></a> The National Endowment for the Humanities funds stuff like this!</li>\n</ul>",
      # rubocop:disable StringLiterals
      thumbnail_html: "<p><img src=\"https://s3.amazonaws.com/americanarchive.org/special-collections/CivilWarKenBurns.jpg\" alt=\"Test Thumbnail\" title=\"Test Thumbnail\"></p>",
      # rubocop:enable StringLiterals
      help_html: '<p>This is the search help text.</p>'
    }

    # rubocop:enable LineLength
    assertions.each do |method, value|
      it "#{method} method works" do
        expect(collection.send(method)).to eq((begin
                                              value.strip
                                            rescue
                                              value
                                            end))
      end
    end

    it 'tests everthing' do
      expect(assertions.keys.sort)
        .to eq((SpecialCollection.instance_methods(false) + Cmless.instance_methods(false)).sort)
    end

    describe 'error handling' do
      it 'raises an error for bad paths' do
        expect { MockSpecialCollection.find_by_path('no/such/path') }.to raise_error(Cmless::Error)
      end
    end
  end
end

require_relative '../../app/models/exhibit'

describe Exhibit do
  
  class MockExhibit < Exhibit
    def self.exhibit_root
      Rails.root + 'spec/fixtures/exhibits'
    end
  end
  
  exhibit = MockExhibit.find_by_path('parent/child/grandchild')
  
  assertions = {
    name: 'Grandchild!',
    path: 'parent/child/grandchild',
    facets: {"genres"=>[], "topics"=>[]},
    ancestors: [MockExhibit.find_by_path('parent'), MockExhibit.find_by_path('parent/child')],
    children: [],
    items: {},
    ids: [],
    summary_html: "<p>Summary goes here.</p>",
    thumbnail_url: 'http://example.org/image',
    author_html: '<p>Author goes here.</p>',
    links: [["LoC", "http://loc.gov"], ["WGBH", "http://wgbh.org"]],
    body_html: '<p>Description goes here.</p>'
  }

  assertions.each do |method, value|
    it "\##{method} works" do
      expect(exhibit.send(method)).to eq(value)
    end
  end

  it 'tests everthing' do
    expect(assertions.keys.sort).to eq(Exhibit.instance_methods(false).sort)
  end
   
end

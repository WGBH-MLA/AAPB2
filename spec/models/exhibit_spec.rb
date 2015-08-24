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
      path: 'parent/child/grandchild',
      facets: { 'genres' => [], 'topics' => [] },
      ancestors: [
        MockExhibit.find_by_path('parent'),
        MockExhibit.find_by_path('parent/child')],
      children: [
        MockExhibit.find_by_path('parent/child/grandchild/greatgrandchild1'),
        MockExhibit.find_by_path('parent/child/grandchild/greatgrandchild2')],
      items: {
        'cpb-aacip_80-12893j6c' => 'item 1',
        'cpb-aacip_37-31cjt2qs' => 'item 2',
        'cpb-aacip_192-1937pxnq' => 'fuller description' },
      ids: ['cpb-aacip_80-12893j6c', 'cpb-aacip_37-31cjt2qs', 'cpb-aacip_192-1937pxnq'],
      summary_html: '<p>Summary goes here.</p>',
      thumbnail_url: 'http://example.org/image',
      author_html: '<p>Author goes here.</p>',
      main_formatted: "<p><a href=\"/catalog/cpb-aacip_80-12893j6c\">item 1</a>\n<a href=\"/catalog/cpb-aacip_37-31cjt2qs\">item 2</a>\n<a href=\"/catalog/cpb-aacip_192-1937pxnq\" title=\"fuller description\">item 3</a></p>",
      head_html: "<p><img src=\"http://example.org/image\" alt=\"alt text\"></p>",
      links_html: "<ul>\n<li><a href=\"http://loc.gov\">LoC</a></li>\n<li><a href=\"http://wgbh.org\">WGBH</a></li>\n</ul>",
      links: [['LoC', 'http://loc.gov'], ['WGBH', 'http://wgbh.org']],
      main_html: <<-EOF
<p><a href="/catalog/cpb-aacip_80-12893j6c">item 1</a>
<a href="/catalog/cpb-aacip_37-31cjt2qs">item 2</a>
<a href="/catalog/cpb-aacip_192-1937pxnq" title="fuller description">item 3</a></p>
      EOF
    }

    assertions.each do |method, value|
      it "\##{method} method works" do
        expect(exhibit.send(method)).to eq((value.strip rescue value))
      end
    end

    it 'tests everthing' do
      expect(assertions.keys.sort)
        .to eq((Exhibit.instance_methods(false) + Cmless.instance_methods(false)).sort)
    end

    describe 'error handling' do
      it 'raises an error for bad paths' do
        expect { MockExhibit.find_by_path('no/such/path') }.to raise_error(IndexError)
      end
    end
  end
end

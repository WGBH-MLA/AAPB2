require 'open-uri'
require 'json'

describe 'Solr' do
  describe 'sort analysis' do
    def analyze(input)
      params = URI.encode_www_form(
        'wt' => 'json',
        'analysis.showmatch' => 'true',
        'analysis.fieldvalue' => input,
        'analysis.fieldtype' => 'sort'
      )
      json = URI('http://localhost:8983/solr/blacklight-core/analysis/field?' + params).read
      JSON.parse(json)['analysis']['field_types']['sort']['index'].last.last['text']
    end
    it 'folds diacritics' do
      expect(analyze('ģrątūītóüś')).to eq('gratuitous')
    end
    it 'normalizes case' do
      expect(analyze('aBcDeFg')).to eq('abcdefg')
    end
    it 'removes non-alphanumerics' do
      expect(analyze('~!@#A$%^&B*()_C[]\\{}|D;:",./<>?`E')).to eq('abcde')
    end
    it 'removes leading articles' do
      expect(analyze('thesis')).to eq('thesis')
      expect(analyze('the end')).to eq('end')
      expect(analyze('an of green gables')).to eq('of green gables')
      expect(analyze('a new hope')).to eq('new hope')
      expect(analyze('g f e d c b a')).to eq('g f e d c b a')
    end
    it '"z" and "0" pads numbers' do
      expect(analyze('3.14')).to eq('zzzz000314')
    end
  end
end

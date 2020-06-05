require_relative '../../app/models/canonical_url'

describe CanonicalUrl do
  let(:id_with_url) { "cpb-aacip-50d685d2587" }
  let(:id_without_url) { "cpb-aacip-12345" }

  describe 'a record with a CanonicalUrl' do
    let(:canonical_url) { described_class.new(id_with_url) }

    it 'returns an id' do
      expect(canonical_url.id).to eq(id_with_url)
    end

    it 'returns a URL' do
      expect(canonical_url.url).to eq("https://www.bloomberg.com/news/videos/2016-11-16/the-david-rubenstein-show-eric-schmidt?srnd=peer-to-peer")
    end
  end

  describe 'a record without a CanonicalUrl' do
    let(:canonical_url) { described_class.new(id_without_url) }

    it 'returns an id' do
      expect(canonical_url.id).to eq(id_without_url)
    end

    it 'returns nil for a URL' do
      expect(canonical_url.url).to eq(nil)
    end
  end

  describe 'creating a CanonicalUrl with an empty ID' do
    it 'raises an error' do
      expect { CanonicalUrl.new("") }.to raise_error('ID required to find canonical_url')
    end
  end
end

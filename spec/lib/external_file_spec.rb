require 'rails_helper'

describe ExternalFile do
  # Enable/disable Webmock before/after this test context.
  before(:all) { WebMock.enable! }
  after(:all) { WebMock.disable! }

  before do
    test_cache = ActiveSupport::Cache.lookup_store(:memory_store)
    allow(Rails).to receive(:cache).and_return(test_cache)
    Rails.cache.clear
  end

  let(:guid) { "cpb-aacip-111-21ghx7d6" }
  let(:url) { "https://s3.amazonaws.com/americanarchive.org/transcripts/#{guid}/#{guid}-transcript.json" }
  let(:content) { File.read('./spec/fixtures/transcripts/cpb-aacip-111-21ghx7d6-transcript.json') }
  let(:external_file) { ExternalFile.new("transcript", guid, url) }

  describe '#guid' do
    context 'when initialized using a GUID with the slash-style' do
      let(:guid) { 'cpb-aacip/111-21ghx7d6' }
      it 'returns normalized GUID' do
        expect(external_file.guid).to eq 'cpb-aacip-111-21ghx7d6'
      end
    end

    context 'when initialized using a GUID with underscore style' do
      let(:guid) { 'cpb-aacip_111-21ghx7d6' }
      it 'returns normalized GUID' do
        expect(external_file.guid).to eq 'cpb-aacip-111-21ghx7d6'
      end
    end
  end

  describe '#cache_key' do
    it 'builds a correct cache key for external file' do
      expect(external_file.cache_key).to eq("transcript/cpb-aacip-111-21ghx7d6")
    end
  end

  context 'when an HTTP request to the URL returns a 200 status' do
    before do
      WebMock.stub_request(:head, url).to_return(status: 200)
      WebMock.stub_request(:get, url).to_return(body: content, status: 200)
    end

    describe '#file_present?' do
      it 'returns true' do
        expect(external_file.file_present?).to eq true
      end

      context 'when called multile times' do
        let(:num_calls) { 3 }
        before do
          allow(external_file).to receive(:head_file).and_return(true)
          num_calls.times { external_file.file_present?(force_check: force_check) }
        end

        context 'when :force_check is false' do
          let(:force_check) { false }
          it 'only calls #head_file once' do
            expect(external_file).to have_received(:head_file).exactly(1).times
          end
        end

        context 'when :force_check is true' do
          let(:force_check) { true }
          it 'calls #head_file every time' do
            expect(external_file).to have_received(:head_file).exactly(num_calls).times
          end
        end
      end
    end

    describe '#file_content' do
      it 'returns the external content' do
        expect(external_file.file_content).to eq(content)
      end
    end
  end

  context "when an HTTP request to the URL returns a non-200 status" do
    before do
      # TODO: Figure out an elegant way to test all non-200 responses.
      WebMock.stub_request(:head, url).to_return(status: 400)
    end

    describe 'file_present?' do
      it 'returns false' do
        expect(external_file.file_present?).to eq false
      end
    end

    describe 'file_content' do
      it 'returns nil' do
        expect(external_file.file_content).to be_nil
      end
    end
  end

  context 'when the url is bad' do
    let(:url) { 'not a url' }
    describe 'file_present?' do
      it 'returns false' do
        expect(external_file.file_present?).to eq false
      end
    end

    describe 'file_content' do
      it 'returns nil' do
        expect(external_file.file_content).to eq nil
      end
    end
  end
end

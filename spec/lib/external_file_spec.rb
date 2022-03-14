require 'external_file'
require 'httparty'

describe ExternalFile do
  before :all do
    # WebMock is disabled by default, but we use it for these tests.
    # Note that it is re-disabled in an :after hook below.
    WebMock.enable!
  end

  json_url = 'https://s3.amazonaws.com/americanarchive.org/transcripts/cpb-aacip-111-21ghx7d6/cpb-aacip-111-21ghx7d6-transcript.json'
  let(:json_example) { File.read('./spec/fixtures/transcripts/cpb-aacip-111-21ghx7d6-transcript.json') }
  let(:external_file) { ExternalFile.new("transcript", "cpb-aacip-111-21ghx7d6", json_url) }

  before do
    # Stub requests so we don't actually have to fetch them remotely. But note
    # that this requires that the files have been pulled down and saved in
    # ./spec/fixtures/transcripts/ with the same filename they have in S3.
    WebMock.stub_request(:any, json_url).to_return(status: 200)
    WebMock.stub_request(:get, json_url).to_return(body: json_example)

    # rather than stub the whole rails cache infrastructure, just bypass
    ExternalFile.any_instance.stub(:file_present?).and_return(true)
  end

  describe '#new' do
    it 'heads the external file' do
      # kind of dumb, stubbed to 200, but tests the struture of class
      expect(external_file.file_present?).to eq(true)
    end

    it 'returns the external content' do
      expect(external_file.file_content).to eq(json_example)
    end

    it 'builds a correct cache key for external file' do
      expect(external_file.cache_key).to eq("transcript/cpb-aacip-111-21ghx7d6")
    end
  end

  after(:all) do
    # Re-disable WebMock so other tests can use actual connections.
    WebMock.disable!
  end
end

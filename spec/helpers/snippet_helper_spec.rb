require 'rails_helper'
require 'webmock'
require 'json'
include ApplicationHelper
include SnippetHelper

describe SnippetHelper do
  before :all do
    # WebMock is disabled by default, but we use it for these tests.
    # Note that it is re-disabled in an :after hook below.
    WebMock.enable!
  end

  json_url = 'https://s3.amazonaws.com/americanarchive.org/transcripts/cpb-aacip-111-21ghx7d6/cpb-aacip-111-21ghx7d6-transcript.json'
  let(:json_example) { File.read('./spec/fixtures/transcripts/cpb-aacip-111-21ghx7d6-transcript.json') }
  let(:json_transcript) { TranscriptFile.new(json_url) }
  let(:transcript_query_1) { %w(ARKANSAS) }
  let(:transcript_query_2) { ["SENATOR PRYOR"] }
  let(:transcript_snippet_1) { TranscriptSnippet.new('transcript' => json_transcript, 'id' => 'cpb-aacip-111-21ghx7d6', 'query' => transcript_query_1) }
  let(:transcript_snippet_2) { TranscriptSnippet.new('transcript' => json_transcript, 'id' => 'cpb-aacip-111-21ghx7d6', 'query' => transcript_query_2) }

  before do
    # Stub requests so we don't actually have to fetch them remotely. But note
    # that this requires that the files have been pulled down and saved in
    # ./spec/fixtures/transcripts/ with the same filename they have in S3.
    WebMock.stub_request(:get, json_url).to_return(body: json_example)
  end

  describe '#new' do
    it 'initializes with the expected attrs' do
      expect(transcript_snippet_1.transcript).to eq(json_transcript)
      expect(transcript_snippet_1.query).to eq(transcript_query_1)
      expect(transcript_snippet_1.id).to eq("cpb-aacip-111-21ghx7d6")
      expect(transcript_snippet_1.full_text).to eq(json_transcript.plaintext)
      expect(transcript_snippet_1.snippet).to eq("...HOST FOR THIS 15TH ANNIVERSARY CELEBRATION AND DEDICATION CEREMONY IS MR. GEORGE CAMPBELL CHAIRMAN OF THE ARKANSAS EDUCATIONAL TELEVISION COMMISSION. GOOD AFTERNOON DISTINGUISHED GUESTS LADIES AND GENTLEMEN WELCOME TO THE...")
      expect(transcript_snippet_1.timecode).to eq("45.37")
      expect(transcript_snippet_1.term).to eq("ARKANSAS")
    end

    it 'fails to initialize with an unexpected attribute' do
      expect { TranscriptSnippet.new('transcript' => json_transcript, 'id' => '123456', 'query' => transcript_query_1, 'nonsense' => 'boogada!') }.to raise_error(/Unexpected attribute for TranscriptSnippet/)
    end

    it 'initializes with expected attrs for compound query' do
      expect(transcript_snippet_2.timecode).to eq("2039.77")
    end
  end

  describe '#url_at_timecode' do
    it 'returns the expected URL with timecode' do
      expect(transcript_snippet_1.url_at_timecode).to eq("/catalog/cpb-aacip-111-21ghx7d6?term=ARKANSAS&proxy_start_time=45.37")
    end
  end

  after(:all) do
    # Re-disable WebMock so other tests can use actual connections.
    WebMock.disable!
  end
end

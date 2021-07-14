require 'rails_helper'
require 'webmock'
require 'json'
include ApplicationHelper
include SnippetHelper

describe TranscriptFile do
  before :all do
    # WebMock is disabled by default, but we use it for these tests.
    # Note that it is re-disable in an :after hook below.
    WebMock.enable!
  end

  json_url = 'https://s3.amazonaws.com/americanarchive.org/transcripts/cpb-aacip-111-21ghx7d6/cpb-aacip-111-21ghx7d6-transcript.json'
  let(:json_example) { File.read('./spec/fixtures/transcripts/cpb-aacip-111-21ghx7d6-transcript.json') }
  let(:json_transcript) { TranscriptFile.new(json_url) }

  text_url = 'https://s3.amazonaws.com/americanarchive.org/transcripts/cpb-aacip-507-0000000j8w/cpb-aacip-507-0000000j8w-transcript.txt'
  let(:text_example) { File.read('./spec/fixtures/transcripts/cpb-aacip-507-0000000j8w-transcript.txt') }
  let(:text_transcript) { TranscriptFile.new(text_url) }

  let(:json_html_tags) { ['play-from-here', 'transcript-row', 'para', 'data-timecodebegin', 'data-timecodeend', 'transcript-row'] }
  let(:text_html_tags) { ['transcript-row', 'para', 'data-timecodebegin', 'transcript-row'] }

  let(:transcript_query_one) { %w(EVENING) }
  let(:transcript_query_two) { %w(NICARAGUAN ECONOMY) }
  let(:transcript_query_three) { %w(LOYE 000000 [SDBA]) }
  let(:transcript_query_four) { ["NICARAGUAN ECONOMY"] }

  before do
    # Stub requests so we don't actually have to fetch them remotely. But note
    # that this requires that the files have been pulled down and saved in
    # ./spec/fixtures/transcripts/ with the same filename they have in S3.
    WebMock.stub_request(:get, json_url).to_return(body: json_example)
    WebMock.stub_request(:get, text_url).to_return(body: text_example)
  end

  describe '#content' do
    it 'returns JSON content from a JSON transcript_src' do
      expect(json_transcript.content).to eq(json_example)
    end

    it 'returns text content from a text transcript_src' do
      expect(text_transcript.content).to eq(text_example)
    end
  end

  describe '#html' do
    it 'returns HTML transcript created from JSON file' do
      expect(Nokogiri::HTML(json_transcript.html).errors.empty?).to eq(true)
    end

    it 'returns HTML transcript created from text file' do
      expect(Nokogiri::HTML(text_transcript.html).errors.empty?).to eq(true)
    end

    it 'returns HTML with expected classes from JSON file' do
      expect(json_html_tags.all? { |tag| json_transcript.html.include?(tag) }).to eq(true)
    end

    it 'returns HTML with expected classes from text file' do
      expect(text_html_tags.all? { |tag| json_transcript.html.include?(tag) }).to eq(true)
    end
  end

  describe '#plaintext' do
    it 'does not include structured_content method html tags' do
      expect(text_html_tags.all? { |tag| text_transcript.plaintext.include?(tag) }).to eq(false)
    end

    it 'does not include newlines' do
      expect(text_transcript.plaintext.include?("\n")).to eq(false)
    end
  end

  describe '#file_type' do
    it 'returns json for json transcript' do
      expect(json_transcript.file_type).to eq(TranscriptFile::JSON_FILE)
    end

    it 'returns text for text transcript' do
      expect(text_transcript.file_type).to eq(TranscriptFile::TEXT_FILE)
    end
  end

  describe '#file_present?' do
    it 'returns true for a record with a JSON transcript' do
      expect(json_transcript.file_present?).to eq(true)
    end

    it 'returns true for a record with a text transcript' do
      expect(text_transcript.file_present?).to eq(true)
    end
  end

  describe '#snippet_from_query' do
    it 'returns the transcript from the beginning if query word is within first 200 characters' do
      transcript = SnippetHelper.snippet_from_query(transcript_query_one, text_transcript.plaintext, 200, ' ')
      # .first returns the preceding '...'
      expect(transcript.split[1]).to eq('JIM')
    end

    it 'truncates the begining of the transcript if keyord is not within first 200 characters' do
      transcript = SnippetHelper.snippet_from_query(transcript_query_two, text_transcript.plaintext, 200, ' ')
      # .first returns the preceding '...'
      expect(transcript.split[1]).to eq('<mark>ECONOMY</mark>.')
    end

    it 'marks compound keyword within a transcript text' do
      transcript = SnippetHelper.snippet_from_query(transcript_query_four, text_transcript.plaintext, 200, ' ')
      expect(transcript).to include('<mark>NICARAGUAN ECONOMY</mark>')
    end

    it 'returns nil transcripts when query not in params' do
      transcript = SnippetHelper.snippet_from_query(transcript_query_three, text_transcript.plaintext, 200, ' ')
      expect(transcript).to eq(nil)
    end
  end

  after(:all) do
    # Re-disable WebMock so other tests can use actual connections.
    WebMock.disable!
  end
end

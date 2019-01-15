require 'rails_helper'
require 'webmock'
include ApplicationHelper
include SnippetHelper

describe CaptionFile do
  before :all do
    # WebMock is disabled by defafult, but we use it for these tests.
    # Note that it is re-disable in an :after hook below.
    WebMock.enable!
  end

  let(:id_1) { 'cpb-aacip-111-02c8693q' }
  let(:srt_example_1) { File.read('./spec/fixtures/captions/srt/example_1.srt') }
  let(:vtt_example_1) { File.read('./spec/fixtures/captions/web_vtt/example_1.vtt') }
  let(:html_example_1) { File.read('./spec/fixtures/captions/html/example_1.html') }
  let(:json_example_1) { JSON.parse(File.read('./spec/fixtures/captions/json/example_1.json')) }
  let(:caption_file_1) { CaptionFile.new(id_1) }

  let(:id_2) { '1a2b' }
  let(:caption_file_2) { CaptionFile.new(id_2) }
  let(:srt_example_2) { File.read('./spec/fixtures/captions/srt/1a2b.srt1.srt') }

  let(:id_3) { 'invalid123' }

  let(:query_with_punctuation) { 'president, eisenhower: .;' }
  let(:query_with_stopwords) { 'the president eisenhower stopworda ' }
  let(:test_array) { %w(PRESIDENT EISENHOWER) }

  let(:caption_query_one) { %w(LITTLE ROCK) }
  let(:caption_query_two) { %w(101ST AIRBORNE) }
  let(:caption_query_three) { %w(LOYE 000000 [SDBA]) }

  before do
    # Stub requests so we don't actually have to fetch them remotely. But note
    # that this requires that the files have been pulled down and saved in
    # ./spec/fixtures/srt/ with the same filename they have in S3.
    WebMock.stub_request(:get, 'https://s3.amazonaws.com/americanarchive.org/captions/cpb-aacip-111-02c8693q/cpb-aacip-111-02c8693q.srt1.srt').to_return(body: srt_example_1)
    WebMock.stub_request(:get, 'https://s3.amazonaws.com/americanarchive.org/captions/cpb-aacip-111-02c8693q/cpb-aacip-111-02c8693q.vtt').to_return(body: vtt_example_1)
    WebMock.stub_request(:get, 'https://s3.amazonaws.com/americanarchive.org/captions/1a2b/1a2b.srt1.srt').to_return(body: srt_example_2)
    WebMock.stub_request(:get, 'https://s3.amazonaws.com/americanarchive.org/captions/invalid123/invalid123.srt1.srt').to_return(status: [500, 'Internal Server Error'])
    # dont need response, just getting through the cap file init
    WebMock.stub_request(:get, 'https://s3.amazonaws.com/americanarchive.org/captions/foo/foo.srt1.srt').to_return(body: '')
  end

  describe '#srt' do
    it 'returns the SRT formatted caption retrieved from remote_url' do
      expect(caption_file_1.srt).to eq srt_example_1
    end
  end

  describe '#vtt' do
    it 'returns the captions formatted as WebVTT' do
      expect(caption_file_1.vtt).to eq vtt_example_1
    end
  end

  describe '#html' do
    it 'returns the captions formatted as HTML' do
      expect(caption_file_1.html).to eq html_example_1
    end
  end

  describe '#text' do
    it 'returns caption text without timecodes' do
      expect(caption_file_1.text).to include('male narrator: IN THE SUMMER OF 1957,')
      expect(caption_file_1.text).not_to include('00:00:38,167 --> 00:00:40,033')
    end
  end

  describe '#json' do
    it 'returns the captions formatted as JSON' do
      expect(JSON.parse(caption_file_1.json)).to eq(json_example_1)
    end
  end

  describe '#snippet_from_query' do
    it 'returns the caption from the beginning if query word is within first 200 characters' do
      caption = snippet_from_query(caption_query_one, caption_file_2.text, 200, '.')

      # .first returns the preceding '...'
      expect(caption.split[1]).to eq('NARRATOR:')
    end

    it 'truncates the begining of the caption if keyord is not within first 200 characters' do
      caption = snippet_from_query(caption_query_two, caption_file_2.text, 200, '.')

      # .first returns the preceding '...'
      expect(caption.split[1]).to eq('<mark>AIRBORNE</mark>.')
    end

    it 'returns nil captions when query not in params' do
      caption = snippet_from_query(caption_query_three, caption_file_2.text, 200, '.')

      expect(caption).to eq(nil)
    end
  end

  describe '#srt_url' do
    it 'returns the URL to the remote SRT caption file' do
      expect(CaptionFile.new('foo').srt_url).to eq 'https://s3.amazonaws.com/americanarchive.org/captions/foo/foo.srt1.srt'
    end
  end

  describe '#vtt_url' do
    it 'returns the URL to the remote VTT caption file' do
      expect(CaptionFile.new('foo').vtt_url).to eq 'https://s3.amazonaws.com/americanarchive.org/captions/foo/foo.vtt'
    end
  end

  describe '.clean_query_for_snippet' do
    it 'removes punctuation from and capitalizes the user query' do
      expect(clean_query_for_snippet(query_with_punctuation)).to eq(test_array)
    end

    it 'uses stopwords.txt to remove words not used in actual search' do
      expect(clean_query_for_snippet(query_with_stopwords)).to eq(test_array)
    end
  end

  after(:all) do
    # Re-disable WebMock so other tests can use actual connections.
    WebMock.disable!
  end
end

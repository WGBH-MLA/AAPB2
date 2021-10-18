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

  let(:caption_file) { CaptionFile.new("1a2b") }

  let(:vtt_example) { File.read('./spec/fixtures/captions/web_vtt/vtt_example.vtt') }
  let(:srt_example) { File.read('./spec/fixtures/captions/srt/srt_example.srt') }
  let(:html_example) { File.read('./spec/fixtures/captions/html/html_example.html') }
  let(:json_example) { File.read('./spec/fixtures/captions/json/json_example.json') }

  let(:query_with_punctuation) { 'president, eisenhower: .;' }
  let(:query_with_stopwords) { 'the president eisenhower stopworda ' }
  let(:test_array) { %w(PRESIDENT EISENHOWER) }

  let(:caption_query_one) { %w(LITTLE ROCK) }
  let(:caption_query_two) { %w(101ST AIRBORNE) }
  let(:caption_query_three) { %w(LOYE 000000 [SDBA]) }
  let(:caption_query_four) { ["LITTLE ROCK"] }

  context 'with a vtt CaptionFile on s3' do
    before do
      CaptionFile.any_instance.stub(:captions_src).and_return('https://s3.amazonaws.com/americanarchive.org/captions/1a2b.vtt')
      WebMock.stub_request(:get, caption_file.vtt_url).to_return(body: vtt_example)
    end

    describe '#vtt?' do
      it 'returns true for a vtt' do
        expect(caption_file.vtt?).to eq(true)
      end
    end

    describe '#vtt' do
      context 'with a file present on s3' do
        it 'returns the captions formatted as WebVTT' do
          expect(caption_file.vtt).to eq vtt_example
        end
      end
    end
  end

  context 'with a srt CaptionFile on s3' do
    before do
      CaptionFile.any_instance.stub(:captions_src).and_return('https://s3.amazonaws.com/americanarchive.org/captions/1a2b.srt')
      WebMock.stub_request(:get, caption_file.srt_url).to_return(body: srt_example)
      WebMock.stub_request(:get, caption_file.vtt_url).to_raise(OpenURI::HTTPError.new('', ''))
    end

    describe '#vtt?' do
      it 'returns false for a vtt' do
        expect(caption_file.vtt?).to eq(false)
      end
    end

    describe '#vtt' do
      it 'converts to vtt from srt' do
        expect(caption_file.vtt).to include vtt_example
      end
    end

    describe '#html' do
      it 'returns the captions formatted as HTML' do
        expect(caption_file.html).to include html_example
      end
    end

    describe '#text' do
      it 'returns caption text without timecodes' do
        expect(caption_file.text).to include('male narrator: IN THE SUMMER OF 1957,')
        expect(caption_file.text).not_to include('00:00:38,167 --> 00:00:40,033')
      end
    end

    describe '#json' do
      it 'returns the captions formatted as JSON string' do
        expect(caption_file.json).to include(json_example.to_s)
      end
    end
  end

  after(:all) do
    # Re-disable WebMock so other tests can use actual connections.
    WebMock.disable!
  end
end

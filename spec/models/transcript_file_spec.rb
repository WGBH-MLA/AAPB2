require 'rails_helper'
require 'webmock'
require 'json'

describe TranscriptFile do
  let(:json_id) { 'cpb-aacip_111-21ghx7d6' }
  let(:text_id) { 'cpb-aacip_507-0000000j8w' }
  let(:fake_id) { '867-5309' }
  let(:no_transcript) { TranscriptFile.new(fake_id) }
  let(:json_transcript) { TranscriptFile.new(json_id) }
  let(:invalid_json) { "['simple string', ['invalid_json'" }
  let(:valid_json) { '{ "start":{"one":"two", "three":"four" }}' }
  let(:text_transcript) { TranscriptFile.new(text_id) }
  let(:json_html_tags) { ['play-from-here', 'transcript-row', 'para', 'data-timecodebegin', 'data-timecodeend', 'transcript-row'] }
  let(:text_html_tags) { ['transcript-row', 'para', 'data-timecodebegin', 'transcript-row'] }

  def valid_json?(json)
    JSON.parse(json)
    return true
  rescue JSON::ParserError
    return false
  end

  describe '#valid_json?' do
    it 'return false for invalid JSON' do
      expect(valid_json?(invalid_json)).to eq(false)
    end

    it 'returns true for valid JSON' do
      expect(valid_json?(valid_json)).to eq(true)
    end
  end

  describe '#json' do
    it 'returns valid JSON transcript retrieved from S3' do
      expect(valid_json?(json_transcript.json)).to eq(true)
    end
  end

  describe '#text' do
    it 'returns a text transcript retrieved from S3' do
      expect(text_transcript.text).to include(File.read(Rails.root.join('spec', 'fixtures', 'transcripts', 'cpb-aacip-507-0000000j8w-transcript.txt')))
    end
  end

  describe '#html' do
    it 'returns HTML transcript created from JSON file' do
      expect(Nokogiri::XML(json_transcript.html).errors.empty?).to eq(true)
    end

    it 'returns HTML transcript created from text file' do
      expect(Nokogiri::XML(text_transcript.html).errors.empty?).to eq(true)
    end

    it 'returns HTML with expected classes from JSON file' do
      expect(json_html_tags.all? { |tag| json_transcript.html.include?(tag) }).to eq(true)
    end

    it 'returns HTML with expected classes from text file' do
      expect(text_html_tags.all? { |tag| json_transcript.html.include?(tag) }).to eq(true)
    end
  end

  describe '#file_present?' do
    it 'returns true for a record with a JSON transcript' do
      expect(json_transcript.file_present?).to eq(true)
    end

    it 'returns true for a record with a text transcript' do
      expect(text_transcript.file_present?).to eq(true)
    end

    it 'returns false for a record without a transcript' do
      expect(TranscriptFile.new('1a2b').file_present?).to eq(false)
    end
  end

  describe '#file_type' do
    it 'returns json for a record with a JSON transcript' do
      expect(json_transcript.file_type).to eq(TranscriptFile::JSON_FILE)
    end

    it 'returns text for a record with a text transcript' do
      expect(text_transcript.file_type).to eq(TranscriptFile::TEXT_FILE)
    end
  end

  describe '#url' do
    it 'returns a text url when text transcript is on S3' do
      expect(text_transcript.url).to eq('https://s3.amazonaws.com/americanarchive.org/transcripts/cpb-aacip-507-0000000j8w/cpb-aacip-507-0000000j8w-transcript.txt')
    end

    it 'returns a json url when json transcript is on S3' do
      expect(json_transcript.url).to eq('https://s3.amazonaws.com/americanarchive.org/transcripts/cpb-aacip-111-21ghx7d6/cpb-aacip-111-21ghx7d6-transcript.json')
    end

    it 'returns nil when no transcript in on S3' do
      expect(no_transcript.url).to eq(nil)
    end
  end

  describe '.json_url' do
    it 'returns the expected S3 URL' do
      expect(TranscriptFile.json_url(json_id)).to eq('https://s3.amazonaws.com/americanarchive.org/transcripts/cpb-aacip-111-21ghx7d6/cpb-aacip-111-21ghx7d6-transcript.json')
    end
  end

  describe '.json_file_present?' do
    it 'returns true for a JSON file present on S3' do
      expect(TranscriptFile.json_file_present?(json_id)).to eq(true)
    end

    it 'returns false for a JSON file not present on S3' do
      expect(TranscriptFile.json_file_present?(fake_id)).to eq(false)
    end
  end

  describe '.text_file_present?' do
    it 'returns true for a text file present on S3' do
      expect(TranscriptFile.text_file_present?(text_id)).to eq(true)
    end

    it 'returns false for a text file not present on S3' do
      expect(TranscriptFile.text_file_present?(fake_id)).to eq(false)
    end
  end
end

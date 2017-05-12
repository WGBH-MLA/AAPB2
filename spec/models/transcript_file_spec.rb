require 'rails_helper'
require 'webmock'
require 'json'

describe TranscriptFile do
  let(:id) { 'cpb-aacip_111-21ghx7d6' }
  let(:fake_id) { '867-5309' }
  let(:transcript) { TranscriptFile.new(id) }
  let(:invalid_json) { "['simple string', ['invalid_json'" }
  let(:valid_json) { '{ "start":{"one":"two", "three":"four" }}' }
  let(:expected_tags) { ['play-from-here', 'transcript-row', 'para', 'data-timecodebegin', 'data-timecodeend', 'transcript-row'] }

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
      expect(valid_json?(transcript.json)).to eq(true)
    end
  end

  describe '#html' do
    it 'returns HTML transcript created from JSON file' do
      expect(Nokogiri::XML(transcript.html).errors.empty?).to eq(true)
    end

    it 'returns HTML with expected classes' do
      expect(expected_tags.all? { |tag| transcript.html.include?(tag) }).to eq(true)
    end
  end

  describe '.json_url' do
    it 'returns the expected S3 URL' do
      expect(TranscriptFile.json_url(id)).to eq('https://s3.amazonaws.com/americanarchive.org/transcripts/cpb-aacip-111-21ghx7d6/cpb-aacip-111-21ghx7d6-transcript.json')
    end
  end

  describe '.file_present?' do
    it 'returns true for file present on S3' do
      expect(TranscriptFile.file_present?(id)).to eq(true)
    end

    it 'returns false for a file not present on S3' do
      expect(TranscriptFile.file_present?(fake_id)).to eq(false)
    end
  end
end

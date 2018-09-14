require 'spec_helper'
require 'transcript_converter'
require 'nokogiri'

describe TranscriptConverter do
  let(:json) { File.read('./spec/fixtures/transcripts/cpb-aacip-111-21ghx7d6-transcript.json') }
  let(:json_html) { File.read('./spec/fixtures/transcripts/cpb-aacip-111-21ghx7d6-transcript.html') }
  let(:text) { File.read('./spec/fixtures/transcripts/cpb-aacip-507-0000000j8w-transcript.txt') }
  let(:text_html) { File.read('./spec/fixtures/transcripts/cpb-aacip-507-0000000j8w-transcript.html') }

  describe '.json_to_html' do
    it 'returns formatted HTML from JSON file' do
      expect(Nokogiri::HTML(TranscriptConverter.json_to_html(json)).errors.empty?).to be true
    end

    it 'returns the expected html' do
      expect(TranscriptConverter.json_to_html(json)).to eq(json_html)
    end
  end

  describe '.text_to_html' do
    it 'returns formatted HTML from text file' do
      expect(Nokogiri::HTML(TranscriptConverter.text_to_html(text)).errors.empty?).to be(true)
    end
  end
end

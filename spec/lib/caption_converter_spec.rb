require 'spec_helper'
require 'caption_converter'

describe CaptionConverter do
  let(:srt) { File.read('./spec/fixtures/captions/srt/example_1.srt') }
  let(:invalid_srt) { File.read('./spec/fixtures/captions/srt/invalid_1.srt') }
  let(:vtt) { File.read('./spec/fixtures/captions/web_vtt/example_1.vtt') }
  let(:html) { File.read('./spec/fixtures/captions/html/example_1.html') }
  let(:text) { File.read('./spec/fixtures/captions/text/example_1.txt') }
  let(:json) { JSON.parse(File.read('./spec/fixtures/captions/json/example_1.json')) }

  describe '.parse_srt' do
    it 'returns an instance of SRT::File with parsed SRT, and no errors' do
      parsed_srt = CaptionConverter.parse_srt(srt)
      expect(parsed_srt).to be_a SRT::File
      expect(parsed_srt.errors).to be_empty
    end

    it 'returns nil when given an invalid SRT string' do
      expect(CaptionConverter.parse_srt(invalid_srt)).to be_nil
    end
  end

  describe '.srt_to_vtt' do
    it 'converts a caption in SRT format to WebVTT format' do
      expect(CaptionConverter.srt_to_vtt(srt)).to eq vtt
    end
  end

  describe '.srt_to_vtt' do
    it 'converts a caption in SRT format to HTML' do
      expect(CaptionConverter.srt_to_html(srt)).to eq html
    end
  end

<<<<<<< 767c2e8d65335dc5db93e95de0c4d02b9bf61348
  describe '.srt_to_text' do
    it 'converts the text from a caption to text' do
      expect(CaptionConverter.srt_to_text(srt)).to eq text
=======
  describe '.srt_to_json' do
    it 'converts a caption in SRT format to JSON' do
      expect(JSON.parse(CaptionConverter.srt_to_json(srt))).to eq json
>>>>>>> Adds transcript to API controller
    end
  end
end

require 'spec_helper'
require 'caption_converter'

describe CaptionConverter do
  let(:srt) { File.read('./spec/fixtures/captions/srt/1a2b.srt1.srt') }
  let(:invalid_srt) { File.read('./spec/fixtures/captions/srt/invalid_1.srt') }
  let(:vtt) { File.read('./spec/fixtures/captions/web_vtt/1a2b.vtt') }
  let(:html) { File.read('./spec/fixtures/captions/html/1a2b.html') }
  let(:text) { File.read('./spec/fixtures/captions/text/1a2b.txt') }
  let(:json) { File.read('./spec/fixtures/captions/json/1a2b.json') }

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
      expect(CaptionConverter.srt_to_vtt(srt)).to include vtt
    end
  end

  describe '.srt_to_vtt' do
    it 'converts a caption in SRT format to html' do
      expect(CaptionConverter.srt_to_transcript(srt).to_html).to include html
    end
  end

  describe '.srt_to_text' do
    it 'converts the text from a caption to text' do
      expect(CaptionConverter.srt_to_text(srt)).to include text
    end
  end

  describe '.srt_to_json' do
    it 'converts a caption in SRT format to JSON' do
      expect(CaptionConverter.srt_to_json(srt)).to include json
    end
  end
end

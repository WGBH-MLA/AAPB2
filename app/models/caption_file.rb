require 'open-uri'
require 'net/http'
require_relative '../../lib/caption_converter'

class CaptionFile
  URL_BASE = 'https://s3.amazonaws.com/americanarchive.org/captions'.freeze

  attr_reader :id, :captions_src

  def initialize(id)
    @id = id
    @captions_src = captions_src
  end

  # Always use vtt for display which will convert srt to vtt
  # if there is no vtt on S3.
  def vtt
    @vtt ||= begin
      open(vtt_url).read
    rescue OpenURI::HTTPError
      # no vtt found, use srt
      CaptionConverter.srt_to_vtt(srt)
    end
  end

  def srt
    @srt ||= begin
      open(srt_url).read
    rescue OpenURI::HTTPError
      nil
    end
  end

  def file_type
    @file_type ||= begin
                     return nil if captions_src.nil?
                     return "srt" if File.extname(captions_src) == ".srt"
                     return "vtt" if File.extname(captions_src) == ".vtt"
                     nil
                   end
  end

  def vtt?
    return true if file_type == 'vtt'
    false
  end

  def srt_url
    "#{CaptionFile::URL_BASE}/#{id}/#{id}.srt1.srt".gsub('cpb-aacip_', 'cpb-aacip-')
  end

  def vtt_url
    "#{CaptionFile::URL_BASE}/#{id}/#{id}.vtt".gsub('cpb-aacip_', 'cpb-aacip-')
  end

  def captions_src
    return vtt_url if caption_file_present?(vtt_url)
    return srt_url if caption_file_present?(srt_url)
    nil
  end

  def caption_file_present?(url)
    uri = URI.parse(url)
    Net::HTTP.get_response(uri).code == '200'
  end

  # THESE METHODS WOULD NEVER WORK FOR A VTT FILE
  # BEGIN
  def html
    return nil if vtt?
    transcript_data = CaptionConverter.srt_to_transcript(srt)
    return nil unless transcript_data
    transcript_data.to_html
  end

  def text
    return nil if vtt?
    @text ||= CaptionConverter.srt_to_text(srt)
  end

  def json
    return nil if vtt?
    @json ||= CaptionConverter.srt_to_json(srt)
  end
  # END
end

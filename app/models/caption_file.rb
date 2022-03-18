require 'open-uri'
require 'net/http'
require_relative '../../lib/caption_converter'
require_relative '../../lib/external_file'

class CaptionFile < ::ExternalFile
  URL_BASE = 'https://s3.amazonaws.com/americanarchive.org/captions'.freeze

  attr_reader :id, :file_type, :captions_src

  def self.retrieve_captions(id)
    # expect srt captions
    caption_file = CaptionFile.new(id, "srt")
    # but you never know...
    caption_file = CaptionFile.new(id, "vtt") unless caption_file.file_present?

    caption_file
  end



  def initialize(id, file_type)
    # ^ pass in the guid and the caption file type you're currently looking for
    @id = normalize_guid(id)
    @file_type = file_type
    @captions_src = captions_src
    super("caption", @id, @captions_src)
  end

  def captions_src
    # build expected url based on passed in file type
    if @file_type == "vtt"
      "#{CaptionFile::URL_BASE}/#{id}/#{id}.vtt"
    elsif @file_type == "srt"
      "#{CaptionFile::URL_BASE}/#{id}/#{id}.srt1.srt"
    end
  end

  # Always use vtt for display which will convert srt to vtt if there is no vtt on S3.
  def vtt
    @vtt ||= begin
      if @file_type == "vtt"
        file_content
      elsif @file_type == "srt"
        # videojs takes vtt files for captions, so convert srt to vtt where applicable
        CaptionConverter.srt_to_vtt(file_content)
      end
    end
  end

  def srt
    @srt ||= file_content if @file_type == "srt"
  end

  def vtt?
    @file_type == 'vtt'
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
    # may be used as transcript content if there was no vtt transcript file...
    @json ||= CaptionConverter.srt_to_json(srt)
  end
  # END
end

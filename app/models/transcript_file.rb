require 'open-uri'
require_relative '../../lib/transcript_converter'
require_relative '../../lib/external_file'

class TranscriptFile < ExternalFile
  JSON_FILE = 'json'.freeze
  TEXT_FILE = 'text'.freeze

  include IdHelper

  attr_reader :transcript_file_src

  def initialize(guid, transcript_file_src, start_time=nil, end_time=nil)
    @transcript_file_src = transcript_file_src
    super("transcript", guid, transcript_file_src)

    if structured_content && (start_time || end_time)
      if !start_time
        start_time = 0
      end

      if !end_time
        end_time = structured_content['parts'].last
      end

    end
  end

  def html
    @html ||= structured_content.to_html if structured_content
  end

  def plaintext
    @plaintext ||= structured_content.text.delete("\n") if structured_content
  end

  def file_type
    @file_type ||= determine_file_type
  end

  private

  def determine_file_type
    return TranscriptFile::JSON_FILE if transcript_file_src.split('.')[-1] == 'json'
    return TranscriptFile::TEXT_FILE if transcript_file_src.split('.')[-1] == 'txt'
    nil
  end

  def structured_content
    return unless file_present?
    @structured_content ||=
      case file_type
      when TranscriptFile::JSON_FILE
        TranscriptConverter.json_parts(file_content)
      when TranscriptFile::TEXT_FILE
        TranscriptConverter.text_parts(file_content)
      end
  end
end

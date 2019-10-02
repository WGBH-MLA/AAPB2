require 'open-uri'
require_relative '../../lib/transcript_converter'

class TranscriptFile
  JSON_FILE = 'json'.freeze
  TEXT_FILE = 'text'.freeze

  attr_reader :transcript_file_src

  def initialize(transcript_file_src)
    @transcript_file_src = transcript_file_src
  end

  def content
    @content ||= open(transcript_file_src).read
  # Return an empty string if no content is found
  rescue
    ""
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

  def file_present?
    return true if Net::HTTP.get_response(URI.parse(transcript_file_src)).code == '200'
    false
    # Don't want to fail on no response
  rescue
    false
  end

  private

  def determine_file_type
    return TranscriptFile::JSON_FILE if transcript_file_src.split('.')[-1] == 'json'
    return TranscriptFile::TEXT_FILE if transcript_file_src.split('.')[-1] == 'txt'
    nil
  end

  def structured_content
    return if !file_present?
    @structured_content ||=
      case file_type
      when TranscriptFile::JSON_FILE
        TranscriptConverter.json_parts(content)
      when TranscriptFile::TEXT_FILE
        TranscriptConverter.text_parts(content)
      end
  end
end

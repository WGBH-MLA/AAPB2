require 'open-uri'
require_relative '../../lib/transcript_converter'

class TranscriptFile
  URL_BASE = 'https://s3.amazonaws.com/americanarchive.org/transcripts'.freeze
  JSON_FILE = 'json'.freeze
  TEXT_FILE = 'text'.freeze

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def json
    @json ||= open(TranscriptFile.json_url(id)).read
  end

  def text
    @text ||= open(TranscriptFile.text_url(id)).read
  end

  def html
    @html ||= build_html
  end

  def file_present?
    @file_present ||= TranscriptFile.json_file_present?(id) || TranscriptFile.text_file_present?(id) ? true : false
  end

  def file_type
    @file_type ||= determine_file_type
  end

  def url
    @url ||= determine_url
  end

  def self.json_url(id)
    transcript_id = id.tr('_', '-')

    "#{TranscriptFile::URL_BASE}/#{transcript_id}/#{transcript_id}-transcript.json"
  end

  def self.text_url(id)
    transcript_id = id.tr('_', '-')

    "#{TranscriptFile::URL_BASE}/#{transcript_id}/#{transcript_id}-transcript.txt"
  end

  def self.json_file_present?(id)
    return true if Net::HTTP.get_response(URI.parse(TranscriptFile.json_url(id))).code == '200'
    false
  end

  def self.text_file_present?(id)
    return true if Net::HTTP.get_response(URI.parse(TranscriptFile.text_url(id))).code == '200'
    false
  end

  private

  def determine_file_type
    return TranscriptFile::JSON_FILE if TranscriptFile.json_file_present?(id)
    return TranscriptFile::TEXT_FILE if TranscriptFile.text_file_present?(id)
    nil
  end

  def build_html
    case file_type
    when TranscriptFile::JSON_FILE
      return TranscriptConverter.json_to_html(json)
    when TranscriptFile::TEXT_FILE
      return TranscriptConverter.text_to_html(text)
    end
    nil
  end

  def determine_url
    case file_type
    when TranscriptFile::JSON_FILE
      return TranscriptFile.json_url(id)
    when TranscriptFile::TEXT_FILE
      return TranscriptFile.text_url(id)
    end
    nil
  end
end

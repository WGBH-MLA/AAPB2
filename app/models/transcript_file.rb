require 'open-uri'
require 'transcript_converter'

class TranscriptFile
  URL_BASE = 'https://s3.amazonaws.com/americanarchive.org/transcripts'.freeze
  JSON_FILE = 'json'
  TEXT_FILE = 'text'

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def json
    @json ||= open(TranscriptFile.json_url(id)).read
  end

  def text
    @text ||= open(TranscriptFile.text_url(id))
  end

  def html
    @html ||= get_html
  end

  def file_present?
    @file_present ||= TranscriptFile.json_file_present?(id) || TranscriptFile.text_file_present?(id) ? true : false
  end

  def file_type
    @file_type ||= get_file_type
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
  end

  def self.text_file_present?(id)
    return true if Net::HTTP.get_response(URI.parse(TranscriptFile.text_url(id))).code == '200'
    false
  end

  private

  def get_file_type
    if TranscriptFile.json_file_present?(id)
      return TranscriptFile::JSON_FILE
    elsif TranscriptFile.text_file_present?(id)
      return TranscriptFile::TEXT_FILE
    else
      return nil
    end
  end

  def get_html
    case file_type
    when TranscriptFile::JSON_FILE
      TranscriptConverter.json_to_html(json)
    when TranscriptFile::TEXT_FILE
      TranscriptConverter.text_to_html(text)
    else
      nil
    end
  end
end
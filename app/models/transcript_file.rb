require 'open-uri'
require 'transcript_converter'

class TranscriptFile
  URL_BASE = 'https://s3.amazonaws.com/americanarchive.org/transcripts'.freeze

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def json
    @json ||= open(TranscriptFile.json_url(id)).read
  end

  def html
    @html ||= TranscriptConverter.json_to_html(json)
  end

  def self.json_url(id)
    transcript_id = id.tr('_', '-')

    "#{TranscriptFile::URL_BASE}/#{transcript_id}/#{transcript_id}-transcript.json"
  end

  def self.file_present?(id)
    return true if Net::HTTP.get_response(URI.parse(TranscriptFile.json_url(id))).code == '200'
    false
  end
end

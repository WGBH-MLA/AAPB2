require 'json'
require 'nokogiri'
require 'pry'

class TranscriptConverter

  def self.json_to_html(json)
    Nokogiri::XML::Builder.new do |x|
      x.div(class: 'transcript') do
        aggregate_transcript_parts(JSON.parse(json)).each do |part|
          x.div(
            'data-timecodebegin' => as_timestamp(part["start_time"]),
            'data-timecodeend' => as_timestamp(part["end_time"])
          ) do
            x.span(' ',
                   class: 'play-from-here',
                   'data-timecodebegin' => as_timestamp(part["start_time"])
                  )
            # Text content is just to prevent element collapse and keep valid HTML.
            x.text(part["text"])
          end
        end
      end
    end.to_xml.gsub("<?xml version=\"1.0\"?>\n", '')
  end

  def self.as_timestamp(s)
    if s.nil?
      Rails.logger.warn('Timestamp cannot be nil')
    else
      Time.at(s.to_f).utc.strftime('%H:%M:%S.%L')
    end
  end

  def self.aggregate_transcript_parts(json)
    working_parts = []
    aggregated_parts = []
    speaker_id = json["parts"][0]["speaker_id"]

    json["parts"].each do |part|
      if part["speaker_id"] == speaker_id
        working_parts << part
      else
        parsed_part = {}
        parsed_part["start_time"] = working_parts[0]["start_time"]
        parsed_part["end_time"] = working_parts[-1]["end_time"]
        parsed_part["text"] = working_parts.map{|p| p["text"] }.join(" ") + "\n"

        aggregated_parts << parsed_part
        working_parts.clear

        working_parts << part
        speaker_id = part["speaker_id"]
      end
    end
    aggregated_parts
  end
end

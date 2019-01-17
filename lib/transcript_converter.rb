require 'json'
require 'nokogiri'
require_relative 'transcript_viewer_helper'

class TranscriptConverter
  extend TranscriptViewerHelper

  def self.json_parts(json)
    parsed_json = aggregate_transcript_parts(JSON.parse(json))
    build_transcript(parsed_json, 'transcript')
  end

  def self.text_parts(text)
    Nokogiri::XML::Builder.new do |x|
      x.div(class: 'root') do
        para_counter = 1
        text.each_line do |line|
          line = line.tr("\n", '')
          next if line.nil? || line.empty?

          x.div(class: 'transcript-row') do
            x.div(
              id: "para#{para_counter}",
              class: 'para'
            ) do
              x.text(line)
            end
          end
          para_counter += 1
        end
      end
    end.doc.root.children
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
    return working_parts unless json['parts']
    speaker_id = json['parts'][0]['speaker_id']

    json['parts'].each do |part|
      if part['speaker_id'] == speaker_id
        working_parts << part
      else
        parsed_part = {}
        parsed_part['start_time'] = working_parts[0]['start_time']
        parsed_part['end_time'] = working_parts[-1]['end_time']
        parsed_part['text'] = working_parts.map { |p| p['text'] }.join(' ') + "\n"

        aggregated_parts << parsed_part
        working_parts.clear

        working_parts << part
        speaker_id = part['speaker_id']
      end
    end
    aggregated_parts
  end
end

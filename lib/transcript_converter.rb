require 'json'
require 'nokogiri'
require_relative 'transcript_viewer_helper'

class TranscriptConverter
  extend TranscriptViewerHelper

  def self.json_parts(json, start_time = nil, end_time = nil)
    return nil unless json && json.present?
    parsed_json = JSON.parse(json)
    parts = parsed_json['parts'] if parsed_json['parts'] && parsed_json['parts'].first

    if start_time && end_time
      # pad back 10s
      start_time -= 10
      start_time = 0 if start_time < 0

      # pad forward 10s
      end_time += 60
      # (pad because editor's clip times will not match the transcript chunks and this helps make sure all the target content is included)

      parts = parts.select { |part| part["start_time"].to_f >= start_time && part["end_time"].to_f <= end_time }

      # flag to ignore 60s chunking for primary sets
      # is_primary_set = true
    end

    # just in case of empty 'parts' key in otherwise valid json
    return nil unless parts
    build_transcript(parts, 'transcript', is_primary_set)
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
end

require 'json'
require 'nokogiri'
require_relative 'transcript_viewer_helper'

class TranscriptConverter
  extend TranscriptViewerHelper

  def self.json_parts(json, start_time = nil, end_time = nil)
    return nil unless json && !json.empty?
    parsed_json = JSON.parse(json)
    parts = parsed_json['parts'] if parsed_json['parts'] && parsed_json['parts'].first

    if start_time && end_time

      # pad window a little to help grab the full transcript content
      selected_parts = parts.select { |part| part["start_time"].to_f >= start_time && part["end_time"].to_f <= end_time + 4 }

      # in case of unexpectedly large chunks, just return everything
      selected_parts = parts unless selected_parts.length > 0
    end

    # just in case of empty 'parts' key in otherwise valid json
    return nil unless parts
    build_transcript(parts, 'transcript')
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

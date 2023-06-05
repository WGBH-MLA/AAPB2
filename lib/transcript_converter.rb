require 'nokogiri'
require_relative 'transcript_viewer_helper'

# 
LEFT = 0
RIGHT= 1

class TranscriptConverter
  extend TranscriptViewerHelper

  def self.json_parts(json, start_time = nil, end_time = nil)
    return nil unless json && !json.empty?
    parsed_json = JSON.parse(json)
    parts = parsed_json['parts'] if parsed_json['parts'] && parsed_json['parts'].first

    if start_time && end_time

      start_chunk_index = find_nearest_chunk_index_by_time(start_time, parts, LEFT)
      end_chunk_index = find_nearest_chunk_index_by_time(end_time, parts, RIGHT)
      parts = parts[start_chunk_index..end_chunk_index]
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

def find_nearest_chunk_index_by_time(time, parts, direction=LEFT)
  if direction == LEFT
    parts.each_with_index.inject(0) do |closest_part_index, (this_part, i)|
      # this_part is less than the specified start time, and this_part's start_time is closer to spectime than previous closest (memo)
      this_part["start_time"].to_f < time && new_part_closer?(time, parts[closest_part_index]["end_time"].to_f, this_part["end_time"].to_f) ? i : closest_part_index 
    end
  else
    parts.each_with_index.inject(0) do |closest_part_index, (this_part, i)|
      this_part["end_time"].to_f > time && new_part_closer?(time, parts[closest_part_index]["end_time"].to_f, this_part["end_time"].to_f) ? i : closest_part_index
    end
  end
end

def new_part_closer?(specified_time, closest_part_time, this_part_time)
  ( this_part_time - specified_time ).abs < ( closest_part_time - specified_time ).abs
end

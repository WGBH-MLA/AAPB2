require 'json'
require 'nokogiri'
require_relative 'transcript_viewer_helper'

class TranscriptConverter
  extend TranscriptViewerHelper

  def self.json_parts(json)
    parsed_json = JSON.parse(json)
    parts = parsed_json['parts'] if parsed_json['parts'] && parsed_json['parts'].first
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

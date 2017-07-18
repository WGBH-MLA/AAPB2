require 'json'
require 'nokogiri'

class TranscriptConverter
  def self.json_to_html(json)
    Nokogiri::XML::Builder.new do |x|
      x.div(class: 'transcript content') do
        para_counter = 1
        aggregate_transcript_parts(JSON.parse(json)).each do |part|
          x.div(class: 'transcript-row') do
            x.span(' ', class: 'play-from-here', 'data-timecode' => as_timestamp(part['start_time']))
            x.div(
              id: "para#{para_counter}",
              class: 'para',
              'data-timecodebegin' => as_timestamp(part['start_time']),
              'data-timecodeend' => as_timestamp(part['end_time'])
            ) do
              # Text content is just to prevent element collapse and keep valid HTML.
              x.text(part['text'])
            end
          end
          para_counter += 1
        end
      end
    end.to_xml.gsub("<?xml version=\"1.0\"?>\n", '')
  end

  def self.text_to_html(text)
    Nokogiri::XML::Builder.new do |x|
      x.div(class: 'transcript content') do
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

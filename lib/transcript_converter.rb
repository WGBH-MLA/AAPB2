require 'json'
require 'nokogiri'

class TranscriptConverter
  def self.json_parts(json)
    parsed_json = JSON.parse(json)
    Nokogiri::XML::Builder.new do |x|
      x.div(class: 'root') do
        
        para_counter = 1

        part_data = aggregate_transcript_parts(parsed_json)
        # get our 0 point
        previous_timestamp = part_data.first['start_time'].to_f
        buffer = ''

        part_data.each do |part|
          this_timestamp = part['start_time'].to_f

          unless (this_timestamp - previous_timestamp) > 60
            # add to buffer

            buffer += part['text'].gsub("\n", " ")
            puts "buffer up! #{buffer}"
          else

            # write paragraph
            x.div(class: 'transcript-row') do
              x.span(' ', class: 'play-from-here', 'data-timecode' => as_timestamp(part['start_time']))
              x.div(
                id: "para#{para_counter}",
                class: 'para',
                'data-timecodebegin' => as_timestamp(part['start_time']),
                'data-timecodeend' => as_timestamp(part['end_time'])
              ) do
                # Text content is just to prevent element collapse and keep valid HTML.

                buffer += part['text']
                x.text(buffer)
                puts "FINSIH HIM #{buffer}"
                buffer = ''
                previous_timestamp = this_timestamp
              end
            end
            para_counter += 1
          end
        end
      end
    end.doc.root.children
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

module TranscriptViewerHelper
  CHUNK_LENGTH = 60

  def build_transcript(transcript_parts, source_type)
    @para_counter = 1
    part_end = 0

    Nokogiri::XML::Builder.new do |doc_root|
      doc_root.div(class: 'root') do
        last_part_end, _discard = timecode_parts(transcript_parts.first, source_type)
        new_part_text = ""
        final_part_end = final_end_time(transcript_parts, source_type)

        transcript_parts.each_with_index do |part,i|
          part_end, part_text = timecode_parts(part, source_type)

          # dont add another space at the beginning of every new part
          new_part_text += " " unless new_part_text == ""
          new_part_text += part_text.tr("\n", " ")

          if ready_for_next_chunk(part_end, last_part_end)
            # write a row whenever we've covered enough time

            build_transcript_row(doc_root, last_part_end, part_end, new_part_text)
            @para_counter += 1

            # set new start marker
            last_part_end = part_end

            # int for next part
            new_part_text = ""
          end
        end

        # write one more for the remainder!
        build_transcript_row(doc_root, part_end, final_part_end, new_part_text)

      end
    end.doc.root.children
  end

  def build_transcript_row(root, start_time, end_time, buffer)
    root.div(class: 'transcript-row') do
      root.span(' ', class: 'play-from-here', 'data-timecode' => as_timestamp(start_time))
      root.div(
        id: "para#{@para_counter}",
        class: 'para',
        'data-timecodebegin' => as_timestamp(start_time),
        'data-timecodeend' => as_timestamp(end_time)
      ) do
        # Text content is just to prevent element collapse and keep valid HTML.
        root.text(buffer)
        # puts "FINSIH HIM #{@buffer}"
      end
    end
  end

  def timecode_parts(part, source_type)
    case source_type
    when 'transcript'
      return part['start_time'].to_f, part['text']
    when 'caption'
      return part.start_time.to_f, part.text.first
    end
  end

  def final_end_time(parts, source_type)
    case source_type
    when 'transcript'
      return parts.last['end_time'].to_f
    when 'caption'
      return parts.last.end_time.to_f
    end
  end

  def ready_for_next_chunk(current_end_time, previous_end_time)
    current_end_time - previous_end_time > CHUNK_LENGTH
  end
end

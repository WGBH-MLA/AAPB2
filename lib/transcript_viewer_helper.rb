module TranscriptViewerHelper
  def build_transcript(transcript_parts, source_type)
    @para_counter = 1

    # make sure new_end_time is in this scope in case of < 60 case
    new_end_time, _discard = timecode_parts(transcript_parts.first, source_type)
    last_end_time = new_end_time
    # initialize so we can += below
    buffer = ''
    Nokogiri::XML::Builder.new do |doc_root|
      doc_root.div(class: 'root') do
        transcript_parts.each_with_index do |part, i|
          new_end_time, text = timecode_parts(part, source_type)
          if (new_end_time - last_end_time) > 60
            build_transcript_row(doc_root, last_end_time, new_end_time, buffer)
            last_end_time = new_end_time

            # text for this step is actually first chunk of next paragraph
            buffer = text
            @para_counter += 1
          else
            buffer += ' ' unless i == 0
            buffer += text.tr("\n", ' ')
          end
        end

        # never wrote a row due to <60s, write one here
        if @para_counter == 1
          build_transcript_row(doc_root, last_end_time, new_end_time, buffer)
        end
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
end

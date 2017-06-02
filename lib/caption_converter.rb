require 'srt'
require 'nokogiri'

class CaptionConverter
  def self.srt_to_vtt(srt)
    parse_srt(srt)
    vtt = srt
    # convert timestamps and save the file
    vtt.gsub!(/([0-9]{2}:[0-9]{2}:[0-9]{2})([,])([0-9]{3})/, '\1.\3')
    # normalize new line character
    vtt.gsub!("\r\n", "\n")
    "WEBVTT\n\n#{vtt}".strip
  end

  def self.srt_to_html(srt)
    parsed_srt = parse_srt(srt)

    Nokogiri::XML::Builder.new do |x|
      x.div(class: 'transcript') do
        parsed_srt.lines.each do |line|
          x.div(
            'data-timecodebegin' => as_timestamp(line.start_time),
            'data-timecodeend' => as_timestamp(line.end_time)
          ) do
            x.span(' ',
                   class: 'play-from-here',
                   'data-timecodebegin' => as_timestamp(line.start_time)
                  )
            # Text content is just to prevent element collapse and keep valid HTML.
            x.text(line.text.join("\n"))
          end
        end
      end
    end.to_xml.gsub("<?xml version=\"1.0\"?>\n", '')
  end

  def self.as_timestamp(s)
    if s.nil?
      Rails.logger.warn('Timestamp cannot be nil')
    else
      Time.at(s).utc.strftime('%H:%M:%S.%L')
    end
  end

  def self.parse_srt(srt)
    SRT::File.parse(srt).tap do |parsed|
      Rails.logger.warn(InvalidSRT.new(parsed.errors)) if parsed.errors.any?
    end
  end

  # Custom error class
  class InvalidSRT < StandardError
    def initialize(srt_errors)
      super(format_error_msg(srt_errors))
    end

    private

    def format_error_msg(srt_errors)
      "There were errors parsing the SRT on the following lines:\n\t" + srt_errors.join("\n\t")
    end
  end
end

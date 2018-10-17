require 'srt'
require 'nokogiri'
require 'json'

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
    begin
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
    rescue
      nil
    end
  end

  def self.srt_to_text(srt)
    caption_text = []
    parsed_srt = parse_srt(srt)
    return nil unless parsed_srt
    parsed_srt.lines.each do |line|
      caption_text << line.text
    end

    caption_text.join(' ').tr('>>', '')
  end

  def self.srt_to_json(srt)
    parsed_srt = parse_srt(srt)
    json = {
      'language'  => 'en-US',
      'parts'     => []
    }

    # Forces encoding to UTF-8 to catch when SRT gem returns ASCII-8BIT
    parsed_srt.lines.each do |line|
      json['parts'] << {
        'text'        => line.text.join(' ').to_s.force_encoding('ISO-8859-1').encode('UTF-8'),
        'start_time'  => line.start_time.to_s.force_encoding('ISO-8859-1').encode('UTF-8'),
        'end_time'    => line.end_time.to_s.force_encoding('ISO-8859-1').encode('UTF-8')
      }
    end

    JSON.generate(json)
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
      if parsed.errors.any?
        Rails.logger.warn('Warning: ' + parsed.errors.join(' '))
        return nil
      end
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

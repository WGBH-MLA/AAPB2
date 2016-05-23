require 'srt'
require 'nokogiri'
require 'time'

class Transcripter
  def self.from_srt(srt)
    transcript = SRT::File.parse(srt)
    Nokogiri::XML::Builder.new do |x|
      x.div(class: 'transcript') do
        transcript.lines.each do |line|
          x.div(
            'data-timecodebegin' => Transcripter.as_timestamp(line.start_time),
            'data-timecodeend' => Transcripter.as_timestamp(line.end_time)
          ) do
            x.span(class: 'play-from-here', 'data-timecodebegin' => line.start_time)
            x.text(line.text.join("\n"))
          end
        end
      end
    end.to_xml.gsub("<?xml version=\"1.0\"?>\n", '')
  end

  def self.as_timestamp(s)
    Time.at(s).utc.strftime('%H:%M:%S.%L')
  end
end

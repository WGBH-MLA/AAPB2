require 'srt'
require 'nokogiri'

class Transcripter
  def self.from_srt(srt)
    transcript = SRT::File.parse(srt)
    Nokogiri::XML::Builder.new do |x|
      x.div(class: 'transcript') {
        transcript.lines.each { |line|
          x.div('data-timecodebegin' => line.start_time, 'data-timecodeend' => line.end_time) {
            x.span(class: 'play-from-here', 'data-timecodebegin' => line.start_time)
            x.text(line.text.join("\n"))
          }
        }
      }
    end.to_xml.gsub('<?xml version="1.0"?>', '')
  end
end

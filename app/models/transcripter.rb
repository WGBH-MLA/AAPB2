require 'srt'

class Transcripter
  def self.from_srt(srt)
    transcript = SRT::File.parse(srt)
    transcript.lines.map{|line| CGI.escapeHTML(line.text.join("\n")) }.join('<br>')
  end
end

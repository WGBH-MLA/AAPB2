require 'open-uri'

class ChapterFile
  URL_BASE = 'https://s3.amazonaws.com/americanarchive.org/chapters'.freeze

  def self.vtt_filename(id)
    "#{id}.vtt".gsub('cpb-aacip_', 'cpb-aacip-')
  end

  def self.vtt_url(id)
    "#{ChapterFile::URL_BASE}/#{id}/#{vtt_filename(id)}".gsub('cpb-aacip_', 'cpb-aacip-')
  end

  def self.file_present?(id)
    return true if Net::HTTP.get_response(URI.parse(ChapterFile.vtt_url(id))).code == '200'
    false
  end
end

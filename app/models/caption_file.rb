require 'open-uri'
require_relative '../../lib/caption_converter'

class CaptionFile
  URL_BASE = 'https://s3.amazonaws.com/americanarchive.org/captions'.freeze

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def srt
    @srt ||= begin
      open(srt_url).read
    rescue OpenURI::HTTPError
      nil
    end
  end

  def vtt
    @vtt ||= begin
      open(vtt_url).read
    rescue OpenURI::HTTPError
      # no vtt found, use srt
      CaptionConverter.srt_to_vtt(srt)
    end
  end

  def html
    transcript_data = CaptionConverter.srt_to_transcript(srt)
    return nil unless transcript_data
    transcript_data.to_html
  end

  def text
    @text ||= CaptionConverter.srt_to_text(srt)
  end

  def json
    @json ||= CaptionConverter.srt_to_json(srt)
  end

  def srt_url
    @srt_url ||= "#{CaptionFile::URL_BASE}/#{id}/#{id}.srt1.srt".gsub('cpb-aacip_', 'cpb-aacip-')
  end

  def vtt_url
    @vtt_url ||= "#{CaptionFile::URL_BASE}/#{id}/#{id}.vtt".gsub('cpb-aacip_', 'cpb-aacip-')
  end

  def captions_from_query(query)
    captions = Nokogiri::HTML(html).text

    captions_dictionary = captions.upcase.gsub(/[[:punct:]]/, '').split

    intersection = query & captions_dictionary
    return nil if intersection.empty?

    start = if (captions.upcase.index(/\b(?:#{intersection[0]})\b/) - 200) > 0
              captions.upcase.index(/\b(?:#{intersection[0]})\b/) - 200
            else
              0
            end

    '...' + captions[start..-1].to_s + '...'
  end

  def self.clean_query_for_captions(query)
    stopwords = []
    File.read(Rails.root.join('jetty', 'solr', 'blacklight-core', 'conf', 'stopwords.txt')).each_line do |line|
      next if line.start_with?('#') || line.empty?
      stopwords << line.upcase.strip
    end

    query.upcase.gsub(/[[:punct:]]/, '').split.delete_if { |term| stopwords.include?(term) }
  end
end

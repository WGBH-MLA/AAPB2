require 'open-uri'
require 'net/http'
require_relative '../../lib/caption_converter'

class CaptionFile
  attr_reader :caption_file_src

  def initialize(caption_file_src)
    @caption_file_src = caption_file_src
  end

  def srt
    @srt ||= begin
      open(caption_file_src).read
    rescue OpenURI::HTTPError
      nil
    end
  end

  def vtt
    @vtt ||= vtt? ? open(caption_file_src).read : CaptionConverter.srt_to_vtt(srt)
  end

  def vtt?
    caption_file_src.split('.').last == 'vtt' ? true : false
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

  def caption_file_present?(url)
    uri = URI.parse(url)
    Net::HTTP.get_response(uri).code == '200'
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

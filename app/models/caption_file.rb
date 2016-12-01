require 'open-uri'
require 'caption_converter'

class CaptionFile
  URL_BASE = 'https://s3.amazonaws.com/americanarchive.org/captions'.freeze

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def srt
    @srt ||= open(CaptionFile.srt_url(id)).read
  end

  def vtt
    @vtt ||= CaptionConverter.srt_to_vtt(srt)
  end

  def html
    @html ||= CaptionConverter.srt_to_html(srt)
  end

  def captions_from_query(query)
    captions = Nokogiri::HTML(
      CaptionConverter.srt_to_html(CaptionFile.new(id).srt)).text

    captions_dictionary = captions.upcase.gsub(/[[:punct:]]/, '').split

    query.each do |term|
      if captions_dictionary.include?(term)
        start = if (captions.index(term) - 200) > 0
          captions.index(term) - 200
        else
          0
        end
        return '...' + captions[start..-1].to_s + '...'
      else
        return captions
      end
    end
  end

  def self.clean_query_for_captions(query)
    stopwords = []
    File.read(Rails.root.join('jetty', 'solr', 'blacklight-core', 'conf', 'stopwords.txt')).each_line do |line|
      next if line.start_with?('#') || line.empty?
      stopwords << line.upcase.strip
    end

    query.upcase.gsub(/[[:punct:]]/, '').split.delete_if{|term| stopwords.include?(term)}
  end

  def self.srt_url(id)
    "#{CaptionFile::URL_BASE}/#{id}/#{srt_filename(id)}".gsub('cpb-aacip_', 'cpb-aacip-')
  end

  def self.srt_filename(id)
    "#{id}.srt1.srt"
  end
end

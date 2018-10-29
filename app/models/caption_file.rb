require 'open-uri'
require_relative '../../lib/caption_converter'

class CaptionFile
  URL_BASE = 'https://s3.amazonaws.com/americanarchive.org/captions'.freeze
  attr_reader :id

  def initialize(id, sourcetype = 'srt')
    return nil unless id
    @id = id
    @sourcetype = sourcetype
    return nil unless source
  end

  def source
    @source ||= begin
                  open(source_url).read
                rescue OpenURI::HTTPError
                  # 500 bad!
                  nil
                end
  end

  def source_url
    "#{CaptionFile::URL_BASE}/#{@id}/#{source_filename}".gsub('cpb-aacip_', 'cpb-aacip-')
  end

  def source_filename
    case @sourcetype
    when 'srt'
      "#{id}.srt1.srt"
    when 'vtt'
      "#{id}.vtt"
    end
  end

  def srt
    @srt ||= @sourcetype == 'srt' ? source : ''
  end

  def vtt
    # return the unmodified vtt where applicable, otherwise convert
    @vtt ||= @sourcetype == 'vtt' ? source : CaptionConverter.srt_to_vtt(source)
  end

  def html
    @html ||= CaptionConverter.srt_to_html(source)
  end

  def text
    @text ||= CaptionConverter.srt_to_text(source)
  end

  def json
    @json ||= CaptionConverter.srt_to_json(source)
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

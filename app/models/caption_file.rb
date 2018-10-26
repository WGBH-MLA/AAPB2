require 'open-uri'
require_relative '../../lib/caption_converter'

class CaptionFile
  URL_BASE = 'https://s3.amazonaws.com/americanarchive.org/captions'.freeze
  attr_reader :id

  def initialize(id, sourcetype='srt')
    return nil unless id
    @id = id
    @sourcetype = sourcetype
    return nil unless get_source
  end

  def get_source
    @source ||= open(source_url).read
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
    else
    end
  end

  def srt
    # TODO: write vtt convert method, if thats worth covering
    # @srt ||= @sourcetype == 'srt' ? get_source : CaptionConverter.vtt_to_srt(get_source)
    @srt ||= @sourcetype == 'srt' ? get_source : ''
  end

  def vtt
    # return the unmodified vtt where applicable, otherwise convert
    @vtt ||= @sourcetype == 'vtt' ? get_source : CaptionConverter.srt_to_vtt(get_source)
  end

  def html
    @html ||= CaptionConverter.srt_to_html(get_source)
  end

  def text
    @text ||= CaptionConverter.srt_to_text(get_source)
  end

  def json
    @json ||= CaptionConverter.srt_to_json(get_source)
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

  # TODO: think this can be removed since its really just doing the work of getting the caption twice
  # def self.file_present?(id)
  #   return true if Net::HTTP.get_response(URI.parse(CaptionFile.source_url(id))).code == '200'
  #   false
  # end
end

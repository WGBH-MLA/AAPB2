module AAPB
  S3_BASE = 'https://s3.amazonaws.com/americanarchive.org'.freeze
  QUERY_OR = ' OR '.freeze
  PLAYER_HEIGHT_TRANSCRIPT_4_3 = '422'.freeze
  PLAYER_WIDTH_TRANSCRIPT_4_3 = '562'.freeze
  PLAYER_HEIGHT_NO_TRANSCRIPT_4_3 = '510'.freeze
  PLAYER_WIDTH_NO_TRANSCRIPT_4_3 = '680'.freeze

  PLAYER_HEIGHT_TRANSCRIPT_16_9 = '316'.freeze
  PLAYER_WIDTH_TRANSCRIPT_16_9 = '562'.freeze
  PLAYER_HEIGHT_NO_TRANSCRIPT_16_9 = '383'.freeze
  PLAYER_WIDTH_NO_TRANSCRIPT_16_9 = '680'.freeze

  def self.valid_id?(id)
    id =~ /\Acpb-aacip[\-_\/](\S*)/ ? true : false
  end
end

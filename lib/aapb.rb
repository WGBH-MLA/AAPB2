module AAPB
  S3_BASE = 'https://s3.amazonaws.com/americanarchive.org'.freeze
  QUERY_OR = ' OR '.freeze
  def self.valid_id?(id)
    id =~ /\Acpb-aacip[\-_\/](\S*)/ ? true : false
  end
end

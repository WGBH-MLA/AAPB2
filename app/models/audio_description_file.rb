class AudioDescriptionFile < ExternalFile
  URL_BASE = 'https://s3.amazonaws.com/americanarchive.org/audio_descriptions'.freeze

  attr_reader :id, :url

  def initialize(id)
    @id = normalize_guid(id)
    @url = "#{URL_BASE}/#{id}/master.m3u8"
    super("audio_description_hls", @id, @url)
  end

  def file_present?
    true
  end
end

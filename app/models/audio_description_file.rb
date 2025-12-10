class AudioDescriptionFile < ExternalFile
  URL_BASE = 'https://s3.amazonaws.com/americanarchive.org/audio_descriptions'.freeze

  attr_reader :id, :audio_src

  def initialize(id)
    @id = normalize_guid(id)
    @hls_src = "#{URL_BASE}/#{id}/master.m3u8"
    super("audio_description_hls", @id, @hls_src)
  end

def file_present?
  # optionally check S3 if master.m3u8 exists
  true
end

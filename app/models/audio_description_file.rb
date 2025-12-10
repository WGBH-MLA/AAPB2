class AudioDescriptionFile < ExternalFile
  URL_BASE = 'https://s3.amazonaws.com/americanarchive.org/audio_descriptions'.freeze

  attr_reader :id, :audio_src

  def initialize(id)
    @id = normalize_guid(id)
    @audio_src = "#{URL_BASE}/#{id}/#{id}.mp4"
    super("audio_description", @id, @audio_src)
  end

  # mirroring captions_src in caption_file.rb
  def audio_description_src
    file_present? ? audio_src : nil
  end
end

module GlobalMedia
  ALLOWED_GLOBAL_GUIDS = Set.new(
    YAML.load_file(Rails.root.join('config', 'global_guids.yml'))['allowed']
  )

  def self.allowed?(guid)
    ALLOWED_GLOBAL_GUIDS.include?(guid)
  end
end

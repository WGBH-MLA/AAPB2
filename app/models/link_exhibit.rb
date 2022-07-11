class LinkExhibit
  attr_reader :title
  attr_reader :thumbnail_url
  attr_reader :external_url

  def initialize(title:, external_url:, thumbnail_url:)
    @title = title
    @external_url = external_url
    @thumbnail_url = thumbnail_url
  end

  def full_path
    @external_url
  end
end
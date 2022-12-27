class LinkExhibit
  attr_reader :title
  attr_reader :thumbnail_url
  attr_reader :external_url
  attr_reader :new_tab

  def initialize(title:, external_url:, thumbnail_url:, new_tab: false)
    @title = title
    @external_url = external_url
    @thumbnail_url = thumbnail_url
    @new_tab = new_tab
  end

  def full_path
    @external_url
  end
end
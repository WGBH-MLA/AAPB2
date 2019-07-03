require 'yaml'
require_relative '../../lib/aapb'

class Featured
  attr_reader :id
  attr_reader :org_name
  attr_reader :name
  attr_reader :thumbnail_url

  def self.from_gallery(gallery_name)
    @galleries[gallery_name]
  end

  private

  def initialize(hash)
    @id = hash.delete('id') || raise('expected id')
    @org_name = hash.delete('org_name') || raise('expected org_name')
    @name = hash.delete('name') || raise('expected org_name')
    @thumbnail_url = hash.delete('thumbnail_url') || "#{AAPB::S3_BASE}/featured/#{@id}_gallery.jpg"
    raise("unexpected #{hash}") unless hash == {}
  end

  @galleries = Hash[
    Dir[Rails.root + 'config/featured/*-featured.yml'].map do |gallery_path|
      [
        gallery_path.sub(/.*\//, '').sub('-featured.yml', ''),
        YAML.load_file(gallery_path).map { |hash| Featured.new(hash) }
      ]
    end
  ]

end

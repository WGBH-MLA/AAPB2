require_relative '../../lib/markdowner'
require 'yaml'

class Exhibit
  attr_reader :slug
  attr_reader :name
  attr_reader :ids
  attr_reader :thumbnail_url
  attr_reader :html
  
  def self.find_by_slug(slug)
    @@exhibits[slug]
  end
  
  def self.all
    @@exhibits.values
  end

  private
  
  def pop(hash, key)
    hash.delete(key) || fail("#{key} required")
  end

  def initialize(hash)
    @slug = pop(hash, 'slug')
    @name = pop(hash, 'name')
    @ids = pop(hash, 'ids')
    @thumbnail_url = pop(hash, 'thumbnail_url')
    @html = Markdowner.render(pop(hash, 'md'))
    fail("unexpected #{hash}") unless hash == {}
  end

  @@exhibits = Hash[
    YAML.load_file(Rails.root + 'config/exhibits.yml').map do |hash|
      [hash['slug'], Exhibit.new(hash)]
    end
  ]
end
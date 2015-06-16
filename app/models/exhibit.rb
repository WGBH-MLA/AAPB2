require_relative '../../lib/markdowner'
require 'yaml'

class Exhibit
  attr_reader :slug
  attr_reader :name
  attr_reader :ids
  attr_reader :thumbnail_url
  attr_reader :html
  
  def self.find_by_slug(slug)
    @@exhibits_by_slug[slug]
  end
  
  def self.find_by_name(name)
    @@exhibits_by_name[name]
  end
  
  def self.find_by_item_id(id)
    @@exhibits_by_item_id[id] || []
  end
  
  def self.all
    @@exhibits_by_slug.values
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

  # Lookup by slug is necessary for exhibit pages.
  # Lookup by name is necessary on search results.
  
  @@exhibits_by_slug = Hash[
    YAML.load_file(Rails.root + 'config/exhibits.yml').map do |hash|
      [hash['slug'], Exhibit.new(hash)]
    end
  ]
  
  @@exhibits_by_name = Hash[
    YAML.load_file(Rails.root + 'config/exhibits.yml').map do |hash|
      [hash['name'], Exhibit.new(hash)]
    end
  ]
  
  @@exhibits_by_item_id = Hash[
    Exhibit.all.map{ |exhibit| exhibit.ids }.flatten.uniq.map do |id|
      [id, Exhibit.all.select { |exhibit| exhibit.ids.include?(id) } ]
    end
  ]
end
require_relative '../../lib/markdowner'
require_relative '../../lib/aapb'
require_relative 'state'
require 'yaml'

class Organization
  attr_reader :pbcore_name
  attr_reader :id
  attr_reader :short_name
  attr_reader :facet
  attr_reader :state
  attr_reader :state_abbreviation
  attr_reader :city
  attr_reader :url
  attr_reader :history_html
  attr_reader :productions_html
  attr_reader :logo_src
  attr_reader :summary_html

  private

  def pop(hash, key)
    hash.delete(key) || raise("#{key} required")
  end

  def initialize(hash)
    @pbcore_name = pop(hash, 'pbcore_name')
    @id = pop(hash, 'id').to_s
    @short_name = pop(hash, 'short_name')
    @state = pop(hash, 'state')
    @state_abbreviation = State.find_by_name(@state).abbreviation
    @city = pop(hash, 'city')
    @url = pop(hash, 'url')
    @facet = "#{@short_name} (#{@state_abbreviation})"
    @history_html = Markdowner.render(hash['history_md'])
    @summary_html = Markdowner.render((hash.delete('history_md') || '').sub(/(^.{10,}?\.\s+)([A-Z].*)?/m, '\1'))
    @productions_html = Markdowner.render(hash.delete('productions_md'))
    @logo_src = "#{AAPB::S3_BASE}/org-logos/#{hash.delete('logo_filename')}" if hash['logo_filename']
    raise("unexpected #{hash}") unless hash == {}
  end

  orgs = YAML.load_file(Rails.root + 'config/organizations.yml').map { |hash| Organization.new(hash) }
  @orgs_by_pbcore_name = Hash[orgs.map { |org| [org.pbcore_name, org] }]
  @orgs_by_id          = Hash[orgs.map { |org| [org.id, org] }]
  @orgs_by_state       = Hash[orgs.group_by(&:state)]

  public

  def self.find_by_pbcore_name(pbcore_name)
    @orgs_by_pbcore_name[pbcore_name]
  end

  def self.find_by_id(id)
    @orgs_by_id[id]
  end

  def self.find_by_state(state)
    @orgs_by_state[state]
  end

  def self.all
    @orgs_by_id.values.sort_by(&:state)
  end

  def to_a
    [short_name, city, state]
  end
end

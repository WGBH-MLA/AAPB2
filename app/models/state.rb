require_relative '../../lib/markdowner'
require 'yaml'

class State
  attr_reader :name
  attr_reader :blurb_html
  attr_reader :abbreviation

  private

  def pop(hash, key)
    hash.delete(key) || raise("#{key} required")
  end

  def initialize(hash)
    @name = pop(hash, 'state')
    @abbreviation = pop(hash, 'abbreviation')
    @blurb_html = Markdowner.render(
      begin
        symbolized = Hash[hash.delete('blurb_fill').map { |k, v| [k.to_sym, v] }]
        hash.delete('blurb_md') % symbolized.merge(state: @name)
      end
    ) if hash['blurb_md']
    raise "Unexpected #{hash}" unless hash.empty?
  end

  @states = YAML.load_file(Rails.root + 'config/states.yml').map { |hash| State.new(hash) }
  @states_by_name = Hash[@states.map { |state| [state.name, state] }]
  @states_by_abbreviation = Hash[@states.map { |state| [state.abbreviation, state] }]

  public

  def self.find_by_name(name)
    @states_by_name[name]
  end

  def self.find_by_abbreviation(abbreviation)
    @states_by_abbreviation[abbreviation]
  end

  def self.all
    @states
  end

  def organizations
    Organization.find_by_state(name)
  end
end

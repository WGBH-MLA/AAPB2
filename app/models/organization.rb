require_relative '../../lib/markdowner'
require_relative '../../lib/aapb'
require_relative 'state'
require 'yaml'

class Organization < Cmless
  ROOT = (Rails.root + 'app/views/organizations/md').to_s
  
  attr_reader :short_name_html
  attr_reader :state_html
  attr_reader :city_html
  attr_reader :url_html
  attr_reader :history_html
  attr_reader :productions_html
  attr_reader :logo_html

  def id
    @id ||= path
  end
  
  def pbcore_name
    @pbcore_name ||= title
  end
  
  def summary
    @summary ||= history_html.sub(/(^.{10,}?\.\s+)([A-Z].*)?/m, '\1')
  end
  
  def logo_src
    "#{AAPB::S3_BASE}/org-logos/#{logo_html}" if logo_html
  end

  def facet
    @facet ||= "#{short_name_html} (#{state_abbreviation_html})"
  end
  
  def state_abbreviation
    @state_abbreviation = State.find_by_name(state_html).abbreviation
  end
  
  @orgs_by_pbcore_name = Hash[Organization.map { |org| [org.pbcore_name, org] }]
  @orgs_by_id          = Hash[Organization.map { |org| [org.id, org] }]
  @orgs_by_state       = Hash[Organization.group_by(&:state_html)]

  def self.find_by_pbcore_name(pbcore_name)
    @orgs_by_pbcore_name[pbcore_name]
  end

  def self.find_by_id(id)
    @orgs_by_id[id]
  end

  def self.find_by_state(state)
    @orgs_by_state[state]
  end

  def to_a
    [short_name, city, state]
  end
end

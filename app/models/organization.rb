require_relative '../../lib/markdowner'
require_relative '../../lib/aapb'
require_relative 'state'
require 'yaml'
require 'cgi'

class Organization < Cmless
  ROOT = (Rails.root + 'app/views/organizations/md').to_s

  attr_reader :short_name_html
  attr_reader :state_html
  attr_reader :city_html
  attr_reader :url_html
  attr_reader :history_html
  attr_reader :productions_html
  attr_reader :logo_html

  def self.clean(html)
    CGI.unescape(html.gsub(/<[^>]+>/, ''))
  end

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
    clean = Organization.clean(logo_html)
    clean.empty? ? '' : "#{AAPB::S3_BASE}/org-logos/#{Organization.clean(logo_html)}"
  end

  def facet
    @facet ||= "#{short_name} (#{state_abbreviation})"
  end

  def state_abbreviation
    @state_abbreviation = State.find_by_name(state).abbreviation
  end

  def state
    @state ||= Organization.clean(state_html)
  end

  def city
    @city ||= Organization.clean(city_html)
  end

  def short_name
    # this is really hacky, but the redcarpet gem for in cmless
    # for interpreting md was not recognizing the escaped ampersand
    # and a literal ampersand would display as a '&amp;'
    # fix should probably be in cmless with an update of redcarpet
    # but we're punting that for now.
    @short_name ||= Organization.clean(short_name_html).gsub('&amp;', '&')
  end

  def url
    @url ||= Organization.clean(url_html)
  end

  @orgs_by_pbcore_name = Hash[Organization.map { |org| [org.pbcore_name, org] }]
  @orgs_by_id          = Hash[Organization.map { |org| [org.id, org] }]
  @orgs_by_state       = Hash[Organization.group_by(&:state)]

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

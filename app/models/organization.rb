require_relative '../../lib/carpet_factory'

class Organization
  attr_reader :pbcore_name
  attr_reader :id
  attr_reader :short_name
  attr_reader :state
  attr_reader :state_abbreviation
  attr_reader :city
  attr_reader :url
  attr_reader :history_html
  attr_reader :productions_html
  attr_reader :logo_src
  attr_reader :summary_html

  private

  STATE_ABBREVIATIONS = {
    'Alabama' =>	'AL',
    'Alaska' =>	'AK',
    'Arizona' =>	'AZ',
    'Arkansas' =>	'AR',
    'California' =>	'CA',
    'Colorado' =>	'CO',
    'Connecticut' =>	'CT',
    'Delaware' =>	'DE',
    'Florida' =>	'FL',
    'Georgia' =>	'GA',
    'Hawaii' =>	'HI',
    'Idaho' =>	'ID',
    'Illinois' =>	'IL',
    'Indiana' =>	'IN',
    'Iowa' =>	'IA',
    'Kansas' =>	'KS',
    'Kentucky' =>	'KY',
    'Louisiana' =>	'LA',
    'Maine' =>	'ME',
    'Maryland' =>	'MD',
    'Massachusetts' =>	'MA',
    'Michigan' =>	'MI',
    'Minnesota' =>	'MN',
    'Mississippi' =>	'MS',
    'Missouri' =>	'MO',
    'Montana' =>	'MT',
    'Nebraska' =>	'NE',
    'Nevada' =>	'NV',
    'New Hampshire' =>	'NH',
    'New Jersey' =>	'NJ',
    'New Mexico' =>	'NM',
    'New York' =>	'NY',
    'North Carolina' =>	'NC',
    'North Dakota' =>	'ND',
    'Ohio' =>	'OH',
    'Oklahoma' =>	'OK',
    'Oregon' =>	'OR',
    'Pennsylvania' =>	'PA',
    'Rhode Island' =>	'RI',
    'South Carolina' =>	'SC',
    'South Dakota' =>	'SD',
    'Tennessee' =>	'TN',
    'Texas' =>	'TX',
    'Utah' =>	'UT',
    'Vermont' =>	'VT',
    'Virginia' =>	'VA',
    'Washington' =>	'WA',
    'West Virginia' =>	'WV',
    'Wisconsin' =>	'WI',
    'Wyoming' =>	'WY',
    'DC' =>	'DC',
    'Guam' => 'GU'
  }
  
  def pop(hash, key)
    hash.delete(key) || fail("#{key} required")
  end
  
  def initialize(hash)
    @pbcore_name = pop(hash, 'pbcore_name')
    @id = (pop(hash, 'id')).to_s
    @short_name = pop(hash, 'short_name')
    @state = pop(hash, 'state')
    @state_abbreviation = STATE_ABBREVIATIONS[state] || fail("no such state: #{state}")
    @city = pop(hash, 'city')
    @url = pop(hash, 'url')
    @history_html = CarpetFactory.render(hash['history_md'])
    @summary_html = CarpetFactory.render((hash.delete('history_md') || '').sub(/(^.{10,}?\.\s+)([A-Z].*)?/m, '\1'))
    @productions_html = CarpetFactory.render(hash.delete('productions_md'))
    @logo_src = "http://mlamedia01.wgbh.org/aapb/org-logos/#{hash.delete('logo_filename')}" if hash['logo_filename']
    fail("unexpected #{hash}") unless hash == {}
  end

  # TODO: better idiom for locating configuration files?
  (File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/organizations.yml').tap do |path| 
    orgs = YAML.load_file(path).map { |hash| Organization.new(hash) }
    @@orgs_by_pbcore_name = Hash[orgs.map { |org| [org.pbcore_name, org] } ]
    @@orgs_by_id          = Hash[orgs.map { |org| [org.id, org] } ]
  end

  public

  def self.find_by_pbcore_name(pbcore_name)
    @@orgs_by_pbcore_name[pbcore_name]
  end

  def self.find_by_id(id)
    @@orgs_by_id[id]
  end

  def self.all
    @@orgs_by_id.values.sort_by { |org| org.state }
  end

  def to_a
    [short_name, city, state]
  end
end

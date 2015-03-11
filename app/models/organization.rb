require_relative '../../lib/htmlizer'

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
  attr_reader :logo_filename

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
  
  def initialize(hash)
    @pbcore_name = hash['pbcore_name']
    @id = hash['id'].to_s
    @short_name = hash['short_name']
    @state = hash['state']
    @state_abbreviation = STATE_ABBREVIATIONS[state] || fail("no such state: #{state}")
    @city = hash['city']
    @url = hash['url']
    @history_html = Htmlizer.to_html(hash['history_text'])
    @productions_html = Htmlizer.to_html(hash['productions_text'])
    @logo_filename = hash['logo_filename']
  end

  # TODO: better idiom for locating configuration files?
  (File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/organizations.yml').tap do |path|
    org_hashes = YAML.load_file(path)
    @@orgs_by_pbcore_name = Hash[
      org_hashes.map do |hash|
        org = Organization.new(hash)
        [org.pbcore_name, org]
      end
    ]
    @@orgs_by_id          = Hash[
      org_hashes.map do |hash|
        org = Organization.new(hash)
        [org.id, org]
      end
    ]
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

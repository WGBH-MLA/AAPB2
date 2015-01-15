require_relative 'excel_reader'
require_relative 'htmlizer'

class Organization
  attr_reader :pbcore_name
  attr_reader :id
  attr_reader :full_name
  attr_reader :state
  attr_reader :city
  attr_reader :url
  attr_reader :history_html
  attr_reader :productions_html
  attr_reader :logo_filename
  
  private
  
  def initialize(pbcore_name, id, full_name=nil, state=nil, city=nil, 
      url=nil, history_text=nil, productions_text=nil, logo_filename=nil, notes=nil)
    # TODO: Should all fields be required?
    @pbcore_name = pbcore_name
    @id = id
    @full_name = full_name
    @state = state
    @city = city
    @url = url
    @history_html = Htmlizer::to_html(history_text) if history_text
    @productions_html = Htmlizer::to_html(productions_text) if productions_text
    @logo_filename = logo_filename
  end
  
  # TODO: better idiom for locating configuration files?
  (File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/organizations.xml').tap do |path|
    @@orgs_by_pbcore_name = ExcelReader::read(path,0) { |row| Organization.new(*row) }
    @@orgs_by_id          = ExcelReader::read(path,1) { |row| Organization.new(*row) }
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
  
  def to_s
    "#{id}: #{pbcore_name} (#{city}, #{state})"
  end
 
end
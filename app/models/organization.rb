require_relative 'excel_reader'

class Organization
  attr_reader :id
  attr_reader :full_name
  attr_reader :state
  attr_reader :city
  attr_reader :url
  attr_reader :history_html
  attr_reader :productions_text
  attr_reader :logo_filename
  
  private
  
  def initialize(id, full_name=nil, state=nil, city=nil, url=nil, history_html=nil, productions_text=nil, logo_filename=nil)
    # TODO: Should all fields be required?
    @id = id
    @full_name = full_name
    @state = state
    @city = city
    @url = url
    @history_html = history_html
    @productions_text = productions_text
    @logo_filename = logo_filename
  end
  
  # TODO: better idiom for locating configuration files?
  (File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/organizations.xml').tap do |path|
    @@orgs = ExcelReader::read(path) { |row| Organization.new(*row) }
  end
  
  public
  
  def self.find(id)
    @@orgs[id]
  end
  
  def to_s
    "#{self.id} (TODO: use full_name) (#{self.city}, #{self.state})"
  end
 
end
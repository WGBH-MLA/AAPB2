require 'rexml/document'
require 'rexml/xpath'

class Organization
  attr_reader :code
  attr_reader :full_name
  attr_reader :state
  attr_reader :city
  attr_reader :url
  attr_reader :history_html
  attr_reader :productions_text
  attr_reader :logo_filename
  
  private
  
  def initialize(code, full_name=nil, state=nil, city=nil, url=nil, history_html=nil, productions_text=nil, logo_filename=nil)
    # TODO: Should all fields be required?
    @code = code
    @full_name = full_name
    @state = state
    @city = city
    @url = url
    @history_html = history_html
    @productions_text = productions_text
    @logo_filename = logo_filename
  end
  
  def self.initialize_class
    # TODO: better idiom for locating config files?
    path = File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/organizations.xml'
    xml = File.read(path)
    doc = REXML::Document.new(xml)
    
    row_number = 0
    @@orgs = Hash[
      REXML::XPath.match(doc, '/Workbook/Worksheet[1]/Table/Row').map do |row|
        row_number += 1
        if row_number == 1
          nil
        else
          params = []
          index = 0
          REXML::XPath.match(row, 'Cell/Data').each do |data| 
            index_attribute = data.parent.attributes['Index']
            if index_attribute
              index = index_attribute.to_i # 1-based
            else
              index += 1
            end
            params[index-1] = data.text
          end
          key = params[0]
          begin
            value = Organization.new(*params)
          rescue ArgumentError => e
            raise ArgumentError.new(e.message + " Row #{row_number}. #{params}. #{row}")
          end
          [key,value]
        end
      end.select{|x| x}
    ]
  end
  
  Organization.initialize_class
  
  public
  
  def self.find(code)
    @@orgs[code]
  end
  
  def to_s
    "#{self.code} (#{self.city}, #{self.state})"
  end
 
end
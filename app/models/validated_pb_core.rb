require 'nokogiri'
require_relative 'pb_core'

class ValidatedPBCore < PBCore
  @@schema = Nokogiri::XML::Schema(File.read('lib/pbcore-2.0.xsd'))
  
  def initialize(xml)
    super(xml)
    document = Nokogiri::XML(xml)
    errors = @@schema.validate(document)
    if !errors.empty?
      raise errors.join("\n")
    end
    
    # Warm the object and check for missing data, beyond what the schema enforces:
    (PBCore.instance_methods(false)-[:to_solr]).each do |method|
      begin
        self.send(method)
      rescue => e
        #binding.pry
        errors << e.message
      end
    end
    if !errors.empty?
      raise errors.join("\n")
    end
  end
end
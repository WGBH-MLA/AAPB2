require 'nokogiri'
require_relative 'pb_core'

class ValidatedPBCore < PBCore
  @@schema = Nokogiri::XML::Schema(File.read('lib/pbcore-2.0.xsd'))
  
  def initialize(xml)
    super(xml)
    schema_validate(xml)
    method_validate
  end
  
  private
  
  def schema_validate(xml)
    document = Nokogiri::XML(xml)
    errors = @@schema.validate(document)
    if !errors.empty?
      raise 'Schema validation errors: '+errors.join("\n")
    end
  end
  
  def method_validate
    # Warm the object and check for missing data, beyond what the schema enforces.
    errors = []
    (PBCore.instance_methods(false)-[:to_solr]).each do |method|
      begin
        self.send(method)
      rescue => e
        errors << e.message
      end
    end
    if !errors.empty?
      raise 'Method validation errors: '+errors.join("\n")
    end
  end
  
end
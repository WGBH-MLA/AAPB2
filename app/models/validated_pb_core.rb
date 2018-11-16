require 'nokogiri'
require_relative 'pb_core'

class ValidatedPBCore < PBCore
  SCHEMA = Nokogiri::XML::Schema(File.read('lib/pbcore-2.1.xsd'))

  def initialize(xml)
    super(xml)
    schema_validate(xml)
    method_validate
  end

  private

  def schema_validate(xml)
    document = Nokogiri::XML(xml)
    errors = SCHEMA.validate(document)
    return if errors.empty?
    raise 'Schema validation errors: ' + errors.join("\n")
  end

  def method_validate
    # Warm the object and check for missing data, beyond what the schema enforces.
    # Don't like excluding :transcript_content here, but Rails.logger isn't available during ingest for CaptionConverter.parse_srt
    errors = []
    (PBCore.instance_methods(false) - [:to_solr, :transcript_content, :exhibits]).each do |method|
      begin
        send(method)
      rescue => e
        errors << (["'##{method}' failed: #{e.message}"] + e.backtrace[0..2]).join("\n")
      end
    end

    return if errors.empty?
    raise 'Method validation errors: ' + errors.join("\n")
  end
end

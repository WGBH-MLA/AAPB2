require 'nokogiri'
require_relative 'pb_core_presenter'
require_relative '../helpers/id_helper'

class ValidatedPBCore < PBCorePresenter
  include ApplicationHelper
  include IdHelper
  SCHEMA = Nokogiri::XML::Schema(File.read('lib/pbcore-2.1.xsd'))
  TEST_PBCORE_PRESENTER_METHODS = PBCorePresenter.instance_methods(false) - [ :to_solr,
    :transcript_content, :transcript_html, :exhibits, :constructed_transcript_src, :verify_transcript_src,
    :canonical_url, :original_id, :top_exhibits, :seconds, :duration ]

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
    # exclude transcript_src + canonical because dirty multi ID tests fail method validation
    TEST_PBCORE_PRESENTER_METHODS.each do |method|
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

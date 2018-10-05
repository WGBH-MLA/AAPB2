# -*- encoding : utf-8 -*-
class SolrDocument
  include Blacklight::Solr::Document
  ACCESS_FACET_FIELD = 'access_types'.freeze
  attr_accessor :caption_snippet
  attr_accessor :transcript_snippet
  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  # SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  # SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  # use_extension(Blacklight::Solr::Document::DublinCore)

  def has_caption?
    # self[:xml].include?('Captions URL')
    # Nokogiri::XML(self[:xml]).xpath('//pbcoreAnnotation[@annotationType="Captions URL"]').first
    Nokogiri::XML(self[:xml]).css('pbcoreAnnotation[annotationType="Captions URL"]').first
  end

  def has_transcript?
    # self[:xml].include?('Captions URL')
    # Nokogiri::XML(self[:xml]).xpath('//pbcoreAnnotation[@annotationType="Captions URL"]').first
    Nokogiri::XML(self[:xml]).css('pbcoreAnnotation[annotationType="Transcript URL"]').first
  end
end

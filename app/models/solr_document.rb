# -*- encoding : utf-8 -*-
class SolrDocument
  include Blacklight::Solr::Document
  ACCESS_FACET_FIELD = 'access_types'.freeze
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

  def transcript?
    Nokogiri::XML(self[:xml]).css('pbcoreAnnotation[annotationType="Transcript URL"]').first
  end

  def transcript_src
    Nokogiri::XML(self[:xml]).css('pbcoreAnnotation[annotationType="Transcript URL"]').first.text.strip
  end
end

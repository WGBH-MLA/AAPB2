class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  # handled in catalog_controller instead

  self.default_processor_chain << :quote_handler

  def quote_handler(solr_parameters)
    # turns "quoted" clauses into exact phrase match clauses
    # require('pry');binding.pry
    query = solr_parameters[:q]
    return unless query
    exact_clauses = query.scan(/"[^"]*"/).map { |clause| exactquery(clause.delete(%("))) }
    clean_query = query.gsub(/"[^"]*"/, '')
    solr_parameters[:q] = %(#{exact_clauses.join(' ')}#{clean_query})
    solr_parameters
  end

  def exactquery(string)
    # mandatory OR query for each unstemmed field
    fieldnames = %w(captions_unstemmed
                    text_unstemmed
                    titles_unstemmed
                    contribs_unstemmed
                    title_unstemmed
                    contributing_organizations_unstemmed
                    producing_organizations_unstemmed
                    genres_unstemmed
                    topics_unstemmed
                  )
    %(+(#{fieldnames.map { |fieldname| %(#{fieldname}:"#{string}") }.join(' OR ')}))
  end


  # monkeypatch copy
  def facet_value_to_fq_string(facet_field, value)
      facet_config = blacklight_config.facet_fields[facet_field]

      local_params = []
      local_params << "tag=#{facet_config.tag}" if facet_config && facet_config.tag

      prefix = ''
      prefix = "{!#{local_params.join(' ')}}" unless local_params.empty?

      fq = case
           when (facet_config && facet_config.query)
             facet_config.query[value][:fq]
           when (facet_config && facet_config.date)
             # in solr 3.2+, this could be replaced by a !term query
             "#{prefix}#{facet_field}:#{RSolr.solr_escape(value)}"
           when (value.is_a?(DateTime) || value.is_a?(Date) || value.is_a?(Time))
             "#{prefix}#{facet_field}:#{RSolr.solr_escape(value.to_time.utc.strftime('%Y-%m-%dT%H:%M:%SZ'))}"
           when (value.is_a?(TrueClass) || value.is_a?(FalseClass) || value == 'true' || value == 'false'),
             (value.is_a?(Integer) || (value.to_i.to_s == value if value.respond_to? :to_i)),
             (value.is_a?(Float) || (value.to_f.to_s == value if value.respond_to? :to_f))
             "#{prefix}#{facet_field}:#{RSolr.solr_escape(value.to_s)}"
           when value.is_a?(Range)
             "#{prefix}#{facet_field}:[#{value.first} TO #{value.last}]"
           else
             # Before monkey-patching:
             # "{!raw f=#{facet_field}#{(" " + local_params.join(" ")) unless local_params.empty?}}#{value}"
             # Do all the extra parts matter?
             # BEGIN patch replace
             prefix + value.split(AAPB::QUERY_OR).map { |single| "#{facet_field}:\"#{single}\"" }.join(' ')
        # END patch
      end
    end


end

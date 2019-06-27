class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include ApplicationHelper
  # handled in catalog_controller instead
  # self.default_processor_chain << :quote_handler

  def apply_quote_handler(solr_parameters)
    # turns "quoted" clauses into exact phrase match clauses
    query = solr_parameters[:q]
    return unless query
    exact_clauses = query.scan(/"[^"]*"/).map { |clause| exactquery(clause.delete(%("))) }
    clean_query = query.gsub(/"[^"]*"/, '')
    solr_parameters[:q] = %(#{exact_clauses.join(' ')}#{clean_query})
    solr_parameters
  end

  # Adds date filters to the :fq of the solr params.
  def apply_date_filter(solr_params)
    if date_filter
      solr_params[:fq] ||= []
      solr_params[:fq] << date_filter
    end
    solr_params
  end

  # Date Filter
  # Returns the array of date filters, which are joined with ' OR ' as part
  # of a 'fq' parameter. See apply_date_filter above.
  def date_filter
    @date_filters ||= begin
      if date_range
        %(asset_date: #{date_range})
      end
    end
  end

  # rubocop:disable AllCops
  # Returns the 'before' date time formatted for a Solr query.
  def before_date
    @before_date ||= handle_date_string(blacklight_params['before_date'], 'before') if blacklight_params['before_date']&.present?
  end

  # Returns the 'after' date time formatted for a Solr query.
  def after_date
    @after_date ||= handle_date_string(blacklight_params['after_date'], 'after') if blacklight_params['after_date']&.present?
  end
  # rubocop:enable AllCops

  # Returns the date inputs in the form of a queryable range.
  def date_range
    @date_range ||= if filter_exact_date?
      if after_date
        "[#{after_date} TO #{after_date}]"
      end
    else
      if before_date || after_date
        "[#{after_date || '*'} TO #{before_date || '*'}]"
      end
    end
  end

  def filter_exact_date?
    blacklight_params['exact_or_range'] == 'exact'
  end


  # Quote Handler
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


  # Ye old monkeypatch copy from elsewhere. Now seen here!
  def facet_value_to_fq_string(facet_field, value)
    facet_config = blacklight_config.facet_fields[facet_field]

    local_params = []
    local_params << "tag=#{facet_config.tag}" if facet_config && facet_config.tag

    prefix = ''
    prefix = "{!#{local_params.join(' ')}}" unless local_params.empty?

    case
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

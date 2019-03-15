class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  # handled in catalog_controller instead
  # self.default_processor_chain += [:quote_handler]
  
  def quote_handler(solr_parameters)
    query = solr_parameters[:q]
    exact_clauses = query.scan(/"[^"]*"/).map { |clause| exactquery(clause.gsub(%("), '')) }
    clean_query = query.gsub(/"[^"]*"/, '')
    solr_parameters[:q] = %(#{exact_clauses.join(' ')}#{clean_query})
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

end

require_relative './id_helper'

module BlacklightGUIDFetcher
  include IdHelper

  def fetch_from_solr(guid)
    id_styles(guid).each do |style|
      begin
        resp, docs = fetch(style)
        return [resp, docs] if resp && docs
      rescue Blacklight::Exceptions::RecordNotFound
        next
      end
    end
    [nil, nil]
  end

  def query_from_solr(search)
    resp = query_solr(q: search)
    resp["response"]["docs"].map { |doc| SolrDocument.new(doc) } if resp && resp["response"] && resp["response"]["docs"]
  rescue Blacklight::Exceptions::RecordNotFound
    # return bupkis if bupkis
    []
  end
end

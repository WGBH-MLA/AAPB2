require_relative './id_helper'

module SolrGUIDFetcher
  include IdHelper

  def fetch_all_from_solr(guid, solr)
    id_styles(guid).map do |style|
      begin
        data = solr.get('select', params: { q: "id:#{style}" })
        data["response"]["docs"].first["id"] if data['response']['numFound'].to_i > 0
      rescue
        nil
      end
    end.compact
  end
end

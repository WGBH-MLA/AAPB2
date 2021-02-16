require_relative './id_helper'

module BlacklightGUIDFetcher
  include IdHelper

  def fetch_from_blacklight(guid)
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
end

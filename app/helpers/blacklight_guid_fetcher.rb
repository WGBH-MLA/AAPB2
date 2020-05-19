require_relative './id_helper'

module BlacklightGUIDFetcher
  include IdHelper

  def fetch_from_blacklight(guid)
    id_styles(guid).each do |style|
      begin
        puts style
        resp, docs = fetch(style)
        return [resp, docs] if resp && docs
      rescue Blacklight::Exceptions::RecordNotFound
        nil
      end
    end
  end
end

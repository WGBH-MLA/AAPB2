require 'yaml'
require_relative '../../lib/aapb'
require 'active_support'
require 'active_support/core_ext'

class CanonicalUrl
  # Only a small number of records will have a canonical_url, so they are stored in a YAML file
  # at config/canonical_urls/url_map.yml
  attr_reader :id
  attr_reader :url

  def initialize(id)
    raise "ID required to find canonical_url" unless id.present?
    @id = id
    @url = find_url(@id)
  end

  def find_url(id)
    return nil unless ids_with_urls.include?(id)
    canonical_urls.select { |url| url["id"] == id }.first["url"]
  end

  private

  # Get all the canonical URLs from config
  def canonical_urls
    YAML.load_file(Rails.root + 'config/canonical_urls/url_map.yml')
  end

  def ids_with_urls
    canonical_urls.map { |url| url["id"] }
  end
end

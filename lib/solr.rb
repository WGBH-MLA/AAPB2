require 'yaml'
require 'singleton'
require 'rsolr'

class Solr
  include Singleton

  DEFAULT = 'development'.freeze

  def initialize
    environment = ENV['RAILS_ENV'] || DEFAULT
    conf = YAML.load_file(Rails.root + 'config/blacklight.yml')
    solr_url = ENV['SOLR_URL'] || conf[environment]['url']
    @connect = RSolr.connect(url: solr_url + 'blacklight-core')
  end

  attr_reader :connect
end

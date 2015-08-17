require 'yaml'
require 'singleton'
require 'rsolr'

class Solr
  include Singleton

  DEFAULT = 'development'

  def initialize
    environment = ENV['RAILS_ENV'] || DEFAULT
    conf = YAML.load_file(Rails.root + 'config/blacklight.yml')
    @connect = RSolr.connect(url: conf[environment]['url'])
  end

  attr_reader :connect
end

require 'yaml'
require 'singleton'

class Solr
  include Singleton
  
  DEFAULT = 'development'
  
  def initialize
    environment = ENV['RAILS_ENV'] || DEFAULT
    conf = YAML.load_file(File.dirname(__FILE__) + '/../../config/blacklight.yml')
    @connect = RSolr.connect(url: conf[environment]['url'])
  end
  
  attr_reader :connect
end
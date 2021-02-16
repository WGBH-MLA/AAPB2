require 'pathname'
require 'ostruct'

module Rails
  unless Rails.respond_to?(:root)
    def self.root
      Pathname.new(File.expand_path(File.dirname(File.dirname(__FILE__))))
    end
  end
  unless Rails.respond_to?(:env)
    def self.env
      OpenStruct.new(production?: false)
    end
  end

  unless Rails.respond_to?(:cache)
    def self.cache
      CacheStub.new
    end
  end
end

class CacheStub
  def fetch(key)
    if key == 'maxmind_db'
      MaxMindDB.new(Rails.root + 'config/GeoLite2-Country.mmdb')
    elsif key == 'canonical_urls'
      YAML.load_file(Rails.root + 'config/canonical_urls/url_map.yml')
    end
  end
end

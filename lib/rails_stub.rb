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

  # for geoip
  unless Rails.respond_to?(:cache)
    def self.cache
      OpenStruct.new(fetch: MaxMindDB.new(Rails.root + 'config/GeoLite2-Country.mmdb'))
    end
  end
end

require 'maxminddb'

class GeoLocation
  MMDB_PATH = Rails.root + 'config/GeoLite2-Country.mmdb'
  CACHE_KEY = 'maxmind_db'.freeze

  class << self
    # Looks up an IP address to find out what country it's coming from.
    # @return [String] capitalized, two-character ISO country code of the IP's
    #   origin according to our current copy of MaxMindDB's GeoLite2 Country db.
    def country_code(ip)
      mmdb.lookup(ip).country.iso_code
    end

    # Caches a new instance of MaxMindDB::Client at CACHE_KEY loaded with data
    # from MMDB_PATH and returns it.
    # @return [MaxMindDB::Client] client instance used to look up country of
    #   origin for IP address.
    def mmdb
      Rails.cache.fetch(CACHE_KEY) { MaxMindDB.new(MMDB_PATH) }
    end
  end
end

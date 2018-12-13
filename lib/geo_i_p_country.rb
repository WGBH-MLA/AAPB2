require 'singleton'

class GeoIPCountry
  include Singleton

  def initialize
    @mmdb = Rails.cache.fetch('maxmind_db')
  end

  def country_code(ip)
    look = @mmdb.lookup(ip)
    look.found? && look.country.iso_code
  end
end

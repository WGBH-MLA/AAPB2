require 'singleton'
require 'geoip'

class GeoIPCountry
  include Singleton

  def initialize
    @geo_ip = GeoIP.new(Rails.root + 'config/GeoIP.dat')
  end

  def country_code(ip)
    @geo_ip.country(ip).country_code2
  end
end

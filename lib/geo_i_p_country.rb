require 'singleton'
require 'geoip'
require_relative 'access_control'

class GeoIPCountry
  include Singleton
  
  def initialize
    @geo_ip = GeoIP.new(Rails.root + 'config/GeoIP.dat')
  end
  
  def country_code(ip)
    return 'US' if AccessControl.authorized_ip?(ip) # WGBH not in geolocate database.
    @geo_ip.country(ip).country_code2
  end
end
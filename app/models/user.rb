require 'set'
require 'ipaddr'

class User
  def initialize(request)
    @ua = request.user_agent
    @ip = request.remote_ip
    @referer = request.referer
    @session = request.session
  end

  ONSITE_RANGES = Set[
    IPAddr.new('198.147.175.0/24'), # WGBH
    IPAddr.new('140.147.0.0/16') # LoC
  ] + (Rails.env.production? ? [] : [IPAddr.new('127.0.0.1')])

  def onsite?
    ONSITE_RANGES.map { |range| range.include?(@ip) }.any?
  end

  def usa?
    GeoIPCountry.instance.country_code(@ip) == 'US'
  end

  def bot?
    /bot|spider/i =~ @ua
  end

  def aapb_referer?
    allowed_referrers = [/^(.+\.)?americanarchive\.org$/, /54\.198\.43\.192$/]
    allowed_referrers.select{ |allowed_referrer| URI.parse(@referer).host =~ allowed_referrer }.count > 0
  end

  def affirmed_tos?
    @session[:affirm_terms]
  end
end

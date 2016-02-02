require 'set'
require 'ipaddr'
require_relative '../../lib/geo_i_p_country'

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
    GeoIPCountry.instance.country_code(@ip) == 'US' || onsite?
    # WGBH doesn't actually geocode to USA. No idea why.
  end

  def bot?
    /bot|spider/i =~ @ua
  end

  def aapb_referer?
    [
      /^(.+\.)?americanarchive\.org$/,
      POPUP_HOST_RE,
      /^54\.198\.43\.192$/
    ].any? do |allowed|
      URI.parse(@referer).host =~ allowed
    end
  end
  
  def embed?
    URI.parse(@referer).path =~ /embed/
  end

  def affirmed_tos?
    @session[:affirm_terms] || 
      (!@referer.nil? && URI.parse(@referer).host =~ POPUP_HOST_RE)
    # Casey confirms that Popup counts as affirming ToS.
  end

  POPUP_HOST_RE = /^(.+\.)?popuparchive\.com$/
end

require 'set'
require 'ipaddr'
require_relative '../../lib/geo_i_p_country'

class User
  DARTMOUTH_HOST_RE = /^(.+\.)?meptest\.dartmouth\.edu$/
  POPUP_HOST_RE = /^(.+\.)?popuparchive\.com$/
  AAPB_HOST_RE = /^(.+\.)?americanarchive\.org$/
  AWS_HOST_RE = /^(.+\.)?wgbh-mla\.org$/
  WGBH_IP_RANGE = IPAddr.new('198.147.175.0/24')
  LOC_IP_RANGE = IPAddr.new('140.147.0.0/16')
  DIGITAL_OCEAN_IP_RANGE = IPAddr.new('162.243.123.117/32')

  attr_reader :request

  def initialize(request)
    @request = request
  end

  def onsite?
    onsite_ip_ranges.map { |range| range.include?(request.remote_ip) }.any?
  end

  def usa?
    %w(US PR WS GU MP VI).include?(::GeoIPCountry.instance.country_code(request.remote_ip)) || onsite?
    # WGBH doesn't actually geocode to USA. No idea why.
  end

  def bot?
    !(/bot|spider/i =~ request.user_agent).nil?
  end

  def referer_host
    URI.parse(request.referer).host
  rescue URI::InvalidURIError
    nil
  end

  def aapb_referer?
    aapb_referer_regexes.any? do |aapb_referer_regex|
      referer_host =~ aapb_referer_regex
    end
  end

  def authorized_referer?
    authorized_referer_regexes.any? do |authorized_referer_regex|
      referer_host =~ authorized_referer_regex
    end
  end

  def embed?
    URI.parse(request.referer).path =~ /embed/
  end

  def affirmed_tos?
    request.cookies['orr_rules_of_use'] == 'y'
  end

  private

  def aapb_referer_regexes
    [AAPB_HOST_RE, POPUP_HOST_RE, AWS_HOST_RE]
  end

  def authorized_referer_regexes
    [DARTMOUTH_HOST_RE]
  end

  def onsite_ip_ranges
    @onsite_ip_ranges ||= begin
      ranges = [WGBH_IP_RANGE, LOC_IP_RANGE]
      ranges << IPAddr.new('127.0.0.1') if Rails.env.development?
      ranges << IPAddr.new('::1') if Rails.env.development?
      ranges
    end
  end
end

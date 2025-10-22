require 'set'
require 'ipaddr'
require 'geo_location'

class User
  DARTMOUTH_HOST_RE = /^(.+\.)?meptest\.dartmouth\.edu$/
  DARTMOUTH_HOST_2_RE = /^(.+\.)?pub\.dartmouth\.edu$/
  GITHUB_IO = /^(.+\.)?github\.io$/
  AVIARY_PLATFORM = /^(.+\.)?iiif\.aviaryplatform\.com$/
  AVANNOTATE_RE = /^(.+\.)?avannotate\.netlify\.app$/
  AAPB_HOST_RE = /^(.+\.)?americanarchive\.org$/
  AWS_HOST_RE = /^(.+\.)?wgbh-mla\.org$/
  WGBH_IP_RANGE_1 = IPAddr.new('198.147.175.0/24')
  WGBH_IP_RANGE_2 = IPAddr.new('204.152.12.0/23')

  attr_reader :request

  def initialize(request)
    @request = request
  end

  def onsite?
    onsite_ip_ranges.map { |range| range.include?(request.remote_ip) }.any?
  end

  def usa?
    %w(US PR WS GU MP VI).include?(GeoLocation.country_code(request.remote_ip)) || onsite?
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
    return false unless request.referer
    URI.parse(request.referer).path =~ /embed/
  end

  def affirmed_tos?
    request.cookies['orr_rules_of_use'] == 'y'
  end

  private

  def aapb_referer_regexes
    [AAPB_HOST_RE, AWS_HOST_RE]
  end

  def authorized_referer_regexes
    [DARTMOUTH_HOST_RE, DARTMOUTH_HOST_2_RE, GITHUB_IO, AVIARY_PLATFORM, AVANNOTATE_RE]
  end

  def onsite_ip_ranges
    @onsite_ip_ranges ||= begin
      ranges = [WGBH_IP_RANGE_1, WGBH_IP_RANGE_2]
      ranges << IPAddr.new('127.0.0.1') if Rails.env.development?
      ranges << IPAddr.new('::1') if Rails.env.development?
      ranges
    end
  end
end

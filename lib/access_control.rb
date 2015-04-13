require 'set'
require 'ipaddr'

module AccessControl
  AUTHORIZED_RANGES = Set[
                          IPAddr.new('198.147.175.0/24'), # WGBH
                          IPAddr.new('140.147.0.0/16') # LoC
                      ]
  def self.authorized_ip?(ip)
    AUTHORIZED_RANGES.map { |range| range.include?(ip) }.any?
  end
end

require_relative '../../lib/access_control'

describe AccessControl do
  def expect_authorized(ip)
    expect(AccessControl.authorized_ip?(ip)).to eq true
  end
  def expect_unauthorized(ip)
    expect(AccessControl.authorized_ip?(ip)).to eq false
  end
  def expect_ip_range(below, bottom, top, above)
    expect_unauthorized(below)
    expect_authorized(bottom)
    expect_authorized(top)
    expect_unauthorized(above)
  end
  it 'allows appropriate WGBH access' do
    expect_ip_range('198.147.174.255', '198.147.175.0', '198.147.175.255', '198.147.176.0')
  end
  it 'allows appropriate LoC access' do
    expect_ip_range('140.146.255.255', '140.147.0.0', '140.147.255.255', '140.148.0.0')
  end
end

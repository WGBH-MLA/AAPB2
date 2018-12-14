require_relative '../../lib/geo_i_p_country'
require 'resolv'
require 'maxminddb'

describe GeoIPCountry do
  def country_for_domain(domain)
    GeoIPCountry.instance.country_code(Resolv.getaddress(domain))
  end

  before :each do
    # hope this works!
    Rails.stub_chain(:cache, :fetch).and_return(MaxMindDB.new(Rails.root + 'config/GeoLite2-Country.mmdb'))
  end

  it 'fails gracefully' do
    expect(GeoIPCountry.instance.country_code('0.0.0.0')).to eq false
  end

  it 'puts UMass in US' do
    expect(country_for_domain('umass.edu')).to eq 'US'
  end

  it 'puts canada.ca in CA' do
    expect(country_for_domain('canada.ca')).to eq 'CA'
  end

  # Site seems to be down...
  it 'puts india.gov.in in IN' do
    expect(country_for_domain('india.gov.in')).to eq 'IN'
  end

  it 'puts www.gob.mx in US!!!' do
    expect(country_for_domain('www.gob.mx')).to eq 'US'
  end

  # but...

  #  it 'puts WGBH in US', :caching do # currently '--'
  #    expect(country_for_domain('wgbh.org')).to eq 'US'
  #  end
  #
  #  it 'puts english.gov.cn in CN', :caching do # response varies
  #    expect(country_for_domain('english.gov.cn')).to eq 'US'
  #  end
end

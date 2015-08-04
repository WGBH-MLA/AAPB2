require_relative '../../lib/geo_i_p_country'
require 'resolv'

describe GeoIPCountry do
  def country_for_domain(domain)
    GeoIPCountry.instance.country_code(Resolv.getaddress(domain))
  end
  
  it 'fails gracefully' do
    expect(GeoIPCountry.instance.country_code('0.0.0.0')).to eq '--'
  end
  
  it 'puts MIT in US' do
    expect(country_for_domain('mit.edu')).to eq 'US'
  end
  
  it 'puts BBC in GB' do
    expect(country_for_domain('bbc.co.uk')).to eq 'GB'
  end
  
  it 'puts canada.ca in CA' do
    expect(country_for_domain('canada.ca')).to eq 'CA'
  end
  
  it 'puts india.gov.in in IN' do
    expect(country_for_domain('india.gov.in')).to eq 'IN'
  end
  
  it 'puts www.gob.mx in US!!!' do
    expect(country_for_domain('www.gob.mx')).to eq 'US'
  end
  
  # but...
  
  xit 'puts WGBH in US' do # currently '--'
    expect(country_for_domain('wgbh.org')).to eq 'US'
  end
  
  xit 'puts english.gov.cn in CN' do # response varies
    expect(country_for_domain('english.gov.cn')).to eq 'US'
  end
end

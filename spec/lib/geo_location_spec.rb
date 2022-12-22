require 'geo_location'
require 'resolv'

describe GeoLocation do
  describe '.country_code' do
    let(:subject) { GeoLocation.country_code(ip) }

    context 'when IP is invalid' do
      let(:ip) { '0.0.0.0' }
      it { is_expected.to be_nil }
    end

    context 'when IP is valid' do
      let(:ip) { Resolv.getaddress('americanarchive.org') }
      it { is_expected.to eq 'US' }
    end
  end
end

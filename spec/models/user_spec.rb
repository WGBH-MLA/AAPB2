require 'rails_helper'
require 'ostruct'

describe User do
  # Creat a User instance for testing using a mocked request object.
  let(:user) { User.new(fake_request) }

  # Normally the remote_ip would be 127.0.0.1 in our test environment, but
  # since we're mocking the request object, we need to explicitly set it here.
  let(:fake_request) { double(user_agent: nil, referer: nil, session: nil, remote_ip: '127.0.0.1') }

  describe '#onsite?' do
    context "when remote IP is within the WGBH and LOC IP ranges (i.e. 'on-site')" do
      let(:onsite_ips) do
        # Get onsite IP ranges from private User method, and convert it to a
        # flattened array of strings.
        user.send(:onsite_ip_ranges).map(&:to_range).map(&:minmax).flatten.map(&:to_s)
      end

      it 'returns true' do
        onsite_ips.each do |onsite_ip|
          allow(fake_request).to receive(:remote_ip).and_return(onsite_ip)
          expect(user.onsite?).to eq true
        end
      end
    end

    context "when remote IP is *not* within the WGBH + LOC IP ranges (i.e. 'off-site')" do
      let(:offsite_ips) do
        ['198.147.174.0', '198.147.176.0', '140.146.0.0', '140.148.0.0']
      end

      it 'returns false' do
        offsite_ips.each do |offsite_ip|
          allow(fake_request).to receive(:remote_ip).and_return(offsite_ip)
          expect(user.onsite?).to eq false
        end
      end
    end

    context 'when Rails environment is NOT development (i.e. when it is testing), and the remote IP is 127.0.0.1' do
      it 'returns false' do
        # note default remote_ip of the fake request is 127.0.0.1 (see above)
        expect(user.onsite?).to eq false
      end
    end
  end

  describe '#usa?' do
    require 'socket'

    it 'returns true for US IP addresses' do
      allow(fake_request).to receive(:remote_ip) { '23.48.126.184' }
      # Was doing DNS lookup, but it failed on Travis: Make it more stable.
      expect(user.usa?).to eq true
    end

    it 'returns false for non-US IP addresses' do
      canadian_ip = '50.117.128.0'
      allow(fake_request).to receive(:remote_ip) { canadian_ip }
      expect(user.usa?).to eq false
    end
  end

  describe '#aapb_referer?' do
    @aapb_referers = [
      'http://americanarchive.org',
      'http://demo.americanarchive.org',
      'http://popuparchive.com',
      'http://www.popuparchive.com'
    ]

    @aapb_referers.each do |aapb_referer|
      context "when the referer is '#{aapb_referer}'" do
        # Stub the fake request to return the referer we're trying to test.
        before { allow(fake_request).to receive(:referer) { aapb_referer } }

        it 'returns true' do
          expect(user.aapb_referer?).to eq true
        end
      end
    end

    @non_aapb_referers = [
      'http://example.com',
      'http://123.123.123.123',
      'this is not even a URI',
      nil
    ]

    @non_aapb_referers.each do |non_aapb_referer|
      context "when the referer is '#{non_aapb_referer}'" do
        # Stub the fake request to return the referer we're trying to test.
        before { allow(fake_request).to receive(:referer) { non_aapb_referer } }

        it 'returns false' do
          expect(user.aapb_referer?).to eq false
        end
      end
    end
  end

  describe '#authorized_referer?' do
    @authorized_referers = [
      'http://meptest.dartmouth.edu'
    ]

    @authorized_referers.each do |auth_referer|
      context "when the referer is '#{auth_referer}'" do
        # Stub the fake request to return the referer we're trying to test.
        before { allow(fake_request).to receive(:referer) { auth_referer } }

        it 'returns true' do
          expect(user.authorized_referer?).to eq true
        end
      end
    end

    @non_authorized_referers = [
      'http://example.com',
      'http://123.123.123.123',
      'this is not even a URI',
      nil
    ]

    @non_authorized_referers.each do |non_auth_referer|
      context "when the referer is '#{non_auth_referer}'" do
        # Stub the fake request to return the referer we're trying to test.
        before { allow(fake_request).to receive(:referer) { non_auth_referer } }

        it 'returns false' do
          expect(user.authorized_referer?).to eq false
        end
      end
    end
  end
end

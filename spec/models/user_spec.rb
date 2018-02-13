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

  describe 'abilities' do
    examples = {
      public:    PBCore.new(File.read('./spec/fixtures/pbcore/access-level-public.xml')),
      protected: PBCore.new(File.read('./spec/fixtures/pbcore/access-level-protected.xml')),
      private:   PBCore.new(File.read('./spec/fixtures/pbcore/access-level-private.xml')),
      all:       PBCore.new(File.read('./spec/fixtures/pbcore/access-level-all.xml'))
    }

    onsite_access = {
      public:     { play: true,  skip_tos: true },
      protected:  { play: true,  skip_tos: true },
      private:    { play: false, skip_tos: true },
      all:        { play: false, skip_tos: true }
    }
    no_access = {
      public:     { play: false, skip_tos: true },
      protected:  { play: false, skip_tos: true },
      private:    { play: false, skip_tos: true },
      all:        { play: false, skip_tos: true }
    }

    {
      # on-site possibilities:

      OpenStruct.new(onsite?: true, affirmed_tos?: false, usa?: true, bot?: false) =>
        onsite_access,
      OpenStruct.new(onsite?: true, affirmed_tos?: false, usa?: false, bot?: false) =>
        # usa?: false
        # if LoC or GBH IPs get geocoded outside USA, it should make no difference.
        onsite_access,
      OpenStruct.new(onsite?: true, affirmed_tos?: true, usa?: false, bot?: false) =>
        # affirmed_tos?: true
        # affirming toc (perhaps through a different network) should not break it.
        onsite_access,
      OpenStruct.new(onsite?: true, affirmed_tos?: true, usa?: false, bot?: false) =>
        # usa?: false / affirmed_tos?: true
        # two weird cases together.
        onsite_access,

      # off-site:

      OpenStruct.new(onsite?: false, affirmed_tos?: false, usa?: true, bot?: false) =>
        {
          public:     { play: false, skip_tos: false },
          protected:  { play: false, skip_tos: true },
          private:    { play: false, skip_tos: true },
          all:        { play: false, skip_tos: true }
        },
      OpenStruct.new(onsite?: false, affirmed_tos?: true, usa?: true, bot?: false) =>
        {
          public:     { play: true,  skip_tos: true },
          protected:  { play: false, skip_tos: true },
          private:    { play: false, skip_tos: true },
          all:        { play: false, skip_tos: true }
        },

      # international:

      OpenStruct.new(onsite?: false, affirmed_tos?: false, usa?: false, bot?: false) =>
        no_access,
      OpenStruct.new(onsite?: false, affirmed_tos?: true, usa?: false, bot?: false) =>
        # Maybe you got the TOS domestically, but we still deny access.
        no_access,

      # bot:

      OpenStruct.new(onsite?: false, affirmed_tos?: false, usa?: true, bot?: true) =>
        no_access,
      OpenStruct.new(onsite?: false, affirmed_tos?: false, usa?: false, bot?: true) =>
        # international bot the same
        no_access

    }.each do |user, doc_types|
      context "User #{user.onsite? ? 'on-site' : 'off-site'} and " \
              "TOS #{user.affirmed_tos? ? 'affirmed' : 'not affirmed'} and " \
              "#{user.usa? ? 'domestic' : 'international'} " \
              "#{user.bot? ? 'bot' : 'human'}" do
        ability = Ability.new(user)
        doc_types.each do |access_level, privs|
          describe access_level do
            example = examples[access_level]
            privs.each do |priv, t_f|
              it "can #{t_f ? '' : 'not '}#{priv}" do
                expect(t_f).to eq ability.can?(priv, example)
              end
            end
          end
        end
      end
    end
  end
end

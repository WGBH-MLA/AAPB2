require 'rails_helper'
require 'ostruct'

describe User do

  let(:user) { User.new(fake_request) }
  let(:fake_request) { double(user_agent: nil, referer: nil, session: nil, remote_ip: nil) }

  describe '#onsite?' do

    context "when remote IP is within the WGBH and LOC IP ranges (i.e. 'on-site')" do

      # Lists of all on-site IPs from WGBH and LOC
      let(:wgbh_ips) { IPAddr.new('198.147.175.0/24').to_range.minmax.map(&:to_s) }
      let(:loc_ips) { IPAddr.new('140.147.0.0/16').to_range.minmax.map(&:to_s) }

      let(:test_these_onsite_ips) do
        wgbh_ips + loc_ips
      end

      it 'returns true' do
        test_these_onsite_ips.each do |onsite_ip|
          allow(fake_request).to receive(:remote_ip).and_return(onsite_ip)
          expect(user.onsite?).to eq true
        end
      end
    end

    context "when remote IP is *not* within the WGBH + LOC IP ranges (i.e. 'off-site')" do

      let(:test_these_offsite_ips) do
        ['198.147.174.0', '198.147.176.0', '140.146.0.0', '140.148.0.0']
      end

      it 'returns false' do
        test_these_offsite_ips.each do |offsite_ip|
          allow(fake_request).to receive(:remote_ip).and_return(offsite_ip)
          expect(user.onsite?).to eq false
        end
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
  
  
  describe '#aapb_referrer?' do
    it 'returns true when referrer is the production website' do
      allow(fake_request).to receive(:referer) { 'http://americanarchive.org' }
      expect(user.aapb_referer?).to eq true
    end

    it 'returns true when the referrer is the demo site' do
      # mock the remote IP to be the demo machine's IP
      allow(fake_request).to receive(:referer).and_return('http://54.198.43.192')
      expect(user.aapb_referer?).to eq true
    end

    it 'returns false when the referrer is example.com' do
      # mock an arbitrary non-AAPB IP
      allow(fake_request).to receive(:referer).and_return('http://example.com')
      expect(user.aapb_referer?).to eq false
    end
  end

  describe 'abilities' do
    
    examples = {
      public:    PBCore.new(File.read('./spec/fixtures/pbcore/access-level-public.xml')),
      pub_pro:   PBCore.new(File.read('./spec/fixtures/pbcore/access-level-public-protected-media.xml')),
      protected: PBCore.new(File.read('./spec/fixtures/pbcore/access-level-protected.xml')),
      private:   PBCore.new(File.read('./spec/fixtures/pbcore/access-level-private.xml')),
      all:       PBCore.new(File.read('./spec/fixtures/pbcore/access-level-all.xml'))
    }
    
    onsite_access = {
      public:     { play: true,  skip_tos: true},
      pub_pro:    { play: true,  skip_tos: true},
      protected:  { play: true,  skip_tos: true},
      private:    { play: false, skip_tos: true},
      all:        { play: false, skip_tos: true},
    }
    no_access = {
      public:     { play: false, skip_tos: true},
      pub_pro:    { play: false, skip_tos: true},
      protected:  { play: false, skip_tos: true},
      private:    { play: false, skip_tos: true},
      all:        { play: false, skip_tos: true},
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
          public:     { play: false, skip_tos: false},
          pub_pro:    { play: false, skip_tos: false},
          protected:  { play: false, skip_tos: true},
          private:    { play: false, skip_tos: true},
          all:        { play: false, skip_tos: true},
        },
      OpenStruct.new(onsite?: false, affirmed_tos?: true, usa?: true, bot?: false) =>
        {
          public:     { play: true,  skip_tos: true},
          pub_pro:    { play: true,  skip_tos: true},
          protected:  { play: false, skip_tos: true},
          private:    { play: false, skip_tos: true},
          all:        { play: false, skip_tos: true},
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
        no_access,
      
    }.each do |user, doc_types|
      context "User #{user.onsite? ? 'on-site' : 'off-site'} and " +
              "TOS #{user.affirmed_tos? ? 'affirmed' : 'not affirmed'} and " +
              "#{user.usa? ? 'domestic' : 'international'} " +
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

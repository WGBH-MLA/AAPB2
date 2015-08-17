require 'rails_helper'
require 'cancan/matchers'

describe User do
  
  let(:user) { User.new(fake_request) }
  let(:fake_request) { double(user_agent: nil, referer: nil, session: nil)}

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
      allow(fake_request).to receive(:remote_ip) { IPSocket::getaddress('www.usa.gov') rescue nil }
      expect(user.usa?).to eq true
    end

    it 'returns false for non-US IP addresses' do
      canadian_ip = '50.117.128.0'
      allow(fake_request).to receive(:remote_ip) { canadian_ip }
      expect(user.usa?).to eq false
    end
  end
  
  describe '#bot?' do
    # TODO
  end


  describe 'ablities' do

    let(:ability) { Ability.new(user) }

    # It would be nice to use instance_double here, but CanCan will not work
    # properly unless you use the real class. So we are forced to load real
    # objects here, with new fixtures we had to create, which slows things.
    let(:public_access)    { PBCore.new(File.read('./spec/fixtures/pbcore/access-level-public.xml')) }
    let(:protected_access) { PBCore.new(File.read('./spec/fixtures/pbcore/access-level-protected.xml')) }
    let(:private_access)   { PBCore.new(File.read('./spec/fixtures/pbcore/access-level-private.xml')) }
    let(:all_access)       { PBCore.new(File.read('./spec/fixtures/pbcore/access-level-all.xml')) }

    
    context 'when on site and not affirmed TOS' do
      let(:user) { instance_double(User, onsite?: true, affirmed_tos?: false) }

      it "can not play public content" do
        expect(ability).not_to be_able_to :play,     public_access
        expect(ability).not_to be_able_to :skip_tos, public_access
      end

      it "can not play protected content" do
        expect(ability).not_to be_able_to :play,     protected_access
        expect(ability).not_to be_able_to :skip_tos, protected_access
      end
      
      it "can not play private content" do
        expect(ability).not_to be_able_to :play,     private_access
        expect(ability).to     be_able_to :skip_tos, private_access
      end
      
      it "can not play undigitized content" do
        expect(ability).not_to be_able_to :play,     all_access
        expect(ability).to     be_able_to :skip_tos, all_access
      end
    end    
    
    context 'when on site and affirmed TOS' do
      let(:user) { instance_double(User, onsite?: true, affirmed_tos?: true) }

      it "can play public content" do
        expect(ability).to     be_able_to :play,     public_access
        expect(ability).to     be_able_to :skip_tos, public_access
      end

      it "can play protected content" do
        expect(ability).to     be_able_to :play,     protected_access
        expect(ability).to     be_able_to :skip_tos, protected_access
      end
      
      it "can not play private content" do
        expect(ability).not_to be_able_to :play,     private_access
        expect(ability).to     be_able_to :skip_tos, private_access
      end
      
      it "can not play undigitized content" do
        expect(ability).not_to be_able_to :play,     all_access
        expect(ability).to     be_able_to :skip_tos, all_access
      end
    end
    
    context 'when off site' do
      # TODO: This changes when we open the ORR.
      let(:user) { instance_double(User, onsite?: false, usa?: true, affirmed_tos?: false) }

      it "can not play public content" do
        expect(ability).not_to be_able_to :play,     public_access
        expect(ability).to     be_able_to :skip_tos, private_access
      end

      it "can not play protected content" do
        expect(ability).not_to be_able_to :play,     protected_access
        expect(ability).to     be_able_to :skip_tos, private_access
      end
      
      it "can not play private content" do
        expect(ability).not_to be_able_to :play,     private_access
        expect(ability).to     be_able_to :skip_tos, private_access
      end
      
      it "can not play undigitized content" do
        expect(ability).not_to be_able_to :play,     all_access
        expect(ability).to     be_able_to :skip_tos, all_access
      end
    end
    
    # TODO: When we open the ORR, test international users, and USA bots.
    
  end
  
end
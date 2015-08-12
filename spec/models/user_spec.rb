require 'rails_helper'
require 'cancan/matchers'
require 'ostruct'

describe User do
  
  describe '#onsite?' do
    def expect_authorized(ip)
      user = User.new(OpenStruct.new(remote_ip: ip, user_agent: nil))
      expect(user.onsite?).to eq true
    end

    def expect_unauthorized(ip)
      user = User.new(OpenStruct.new(remote_ip: ip, user_agent: nil))
      expect(user.onsite?).to eq false
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
  
  describe '#usa?' do
    # TODO
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
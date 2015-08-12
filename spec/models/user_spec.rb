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
    let(:user) { instance_double(User) }

    # It would be nice to use instance_double here, but CanCan will not work
    # properly unless you use the real class. So we are forced to load real
    # objects here, with new fixtures we had to create, which slows things.
    let(:pbcore_with_public_access) { PBCore.new(File.read('./spec/fixtures/pbcore/access-level-public.xml')) }
    let(:pbcore_with_protected_access) { PBCore.new(File.read('./spec/fixtures/pbcore/access-level-protected.xml')) }

    context 'when on-site' do

      let(:user) { instance_double(User, "onsite?" => true, "affirmed_tos?" => true) }

      it "can play videos when PBCore says the video is 'public'" do
        expect(ability).to be_able_to :play, pbcore_with_public_access
      end

      it "can play videos when PBCore say the video is 'protected'" do
        expect(ability).to be_able_to :play, pbcore_with_protected_access
      end
    end
  end
  
end
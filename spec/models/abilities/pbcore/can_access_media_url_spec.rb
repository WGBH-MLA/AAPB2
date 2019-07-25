require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  # The 'user' is set with let(:user) in the contexts below.
  subject(:ability) { Ability.new(user) }

  context 'for public PBCore records' do
    # NOTE: CanCan will only work if we use actual PBCore instance. It won't
    # work if you try to use a mock object, e.g. RSpec instance_double.
    let(:public_pbcore_record) { new_pb(build(:pbcore_description_document,
      identifiers: [
        build(:pbcore_identifier, source: 'Sony Ci', value: 'this-makes-it-digitized')
      ],

      annotations: [
        build(:pbcore_annotation, type: 'Level of User Access', value: 'Online Reading Room')
      ]

    )) }
    
    let(:protected_pbcore_record) { new_pb(build(:pbcore_description_document,
      identifiers: [
        build(:pbcore_identifier, source: 'Sony Ci', value: 'this-makes-it-digitized')
      ],

      annotations: [
        build(:pbcore_annotation, type: 'Level of User Access', value: 'On Location')
      ]

    )) }

    describe 'can? :access_media_url' do
      context 'when User is on-site; User is an AAPB referer; User is embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => true, 'aapb_referer?' => true, 'embed?' => true) }
        
        it 'is true for public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        it 'returns true for protected PBCore records' do
          expect(ability).to be_able_to(:access_media_url, protected_pbcore_record)
        end
      end

      context 'when User is on-site; User is an AAPB referer; User is not embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => true, 'aapb_referer?' => true, 'embed?' => false) }

        it 'is true for public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        it 'returns true for protected PBCore records' do
          expect(ability).to be_able_to(:access_media_url, protected_pbcore_record)
        end
      end

      context 'when User is on-site; User is not an AAPB referer; User is embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => true, 'aapb_referer?' => false, 'embed?' => true) }

        it 'returns true for public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        it 'returns true for protected PBCore records' do
          expect(ability).to be_able_to(:access_media_url, protected_pbcore_record)
        end
      end

      context 'when User is on-site; User is not an AAPB referer; User is not embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => true, 'aapb_referer?' => false, 'embed?' => false) }

        it 'returns true for public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        it 'returns true for protected PBCore records' do
          expect(ability).to be_able_to(:access_media_url, protected_pbcore_record)
        end
      end

      context 'when User is not on-site; User is an AAPB referer; User is embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => false, 'aapb_referer?' => true, 'embed?' => true) }

        it 'returns true for public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        it 'returns true for protected PBCore records' do
          expect(ability).to be_able_to(:access_media_url, protected_pbcore_record)
        end
      end

      context 'when User is not on-site; User is an AAPB referer; User is not embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => false, 'aapb_referer?' => true, 'embed?' => false) }

        it 'returns true for public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        it 'returns true for protected PBCore records' do
          expect(ability).to be_able_to(:access_media_url, protected_pbcore_record)
        end
      end

      context 'when User is not on-site; User is not an AAPB referer; User is embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => false, 'aapb_referer?' => false, 'embed?' => true) }

        it 'returns true for public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        it 'returns true for protected PBCore records' do
          expect(ability).to be_able_to(:access_media_url, protected_pbcore_record)
        end
      end

      context 'when User is not on-site; User is not an AAPB referer; User is not embedding the media; User is not an authorized referer' do
        let(:user) { instance_double(User, 'onsite?' => false, 'aapb_referer?' => false, 'embed?' => false, 'authorized_referer?' => false) }

        it 'returns false for public PBCore records' do
          expect(ability).to_not be_able_to(:access_media_url, public_pbcore_record)
        end

        it 'returns false for protected PBCore records' do
          expect(ability).to_not be_able_to(:access_media_url, protected_pbcore_record)
        end
      end

      context 'when User is not on-site; User is not an AAPB referer; User is not embedding the media; User is an authorized referer' do
        let(:user) { instance_double(User, 'onsite?' => false, 'aapb_referer?' => false, 'embed?' => false, 'authorized_referer?' => true) }

        it 'returns true for public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        it 'returns false for protected PBCore records' do
          expect(ability).to_not be_able_to(:access_media_url, protected_pbcore_record)
        end
      end
    end
  end
end

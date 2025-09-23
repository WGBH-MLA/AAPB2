require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  subject(:ability) { Ability.new(user) }

  context 'for PBCore records' do
    let(:public_pbcore_record)    { PBCorePresenter.new(File.read('./spec/fixtures/pbcore/access-level-public.xml')) }
    let(:protected_pbcore_record) { PBCorePresenter.new(File.read('./spec/fixtures/pbcore/access-level-protected.xml')) }
    let(:private_pbcore_record)   { PBCorePresenter.new(File.read('./spec/fixtures/pbcore/access-level-private.xml')) }

    shared_examples 'denies protected and private records' do
      it 'denies access to protected PBCore records' do
        expect(ability).not_to be_able_to(:access_media_url, protected_pbcore_record)
      end

      it 'denies access to private PBCore records' do
        expect(ability).not_to be_able_to(:access_media_url, private_pbcore_record)
      end
    end

    describe 'can? :access_media_url' do
      context 'when User is on-site; User is an AAPB referer; User is embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => true, 'aapb_referer?' => true, 'embed?' => true) }

        it 'allows access to public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        include_examples 'denies protected and private records'
      end

      context 'when User is on-site; User is an AAPB referer; User is not embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => true, 'aapb_referer?' => true, 'embed?' => false) }

        it 'allows access to public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        include_examples 'denies protected and private records'
      end

      context 'when User is on-site; User is not an AAPB referer; User is embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => true, 'aapb_referer?' => false, 'embed?' => true) }

        it 'allows access to public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        include_examples 'denies protected and private records'
      end

      context 'when User is on-site; User is not an AAPB referer; User is not embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => true, 'aapb_referer?' => false, 'embed?' => false) }

        it 'returns true for public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        include_examples 'denies protected and private records'
      end

      context 'when User is not on-site; User is an AAPB referer; User is embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => false, 'aapb_referer?' => true, 'embed?' => true) }

        it 'allows access to public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        include_examples 'denies protected and private records'
      end

      context 'when User is not on-site; User is an AAPB referer; User is not embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => false, 'aapb_referer?' => true, 'embed?' => false) }

        it 'allows access to public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        include_examples 'denies protected and private records'
      end

      context 'when User is not on-site; User is not an AAPB referer; User is embedding the media' do
        let(:user) { instance_double(User, 'onsite?' => false, 'aapb_referer?' => false, 'embed?' => true) }

        it 'allows access to public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        include_examples 'denies protected and private records'
      end

      context 'when User is not on-site; User is not an AAPB referer; User is not embedding the media; User is not an authorized referer' do
        let(:user) { instance_double(User, 'onsite?' => false, 'aapb_referer?' => false, 'embed?' => false, 'authorized_referer?' => false) }

        it 'denies access to public PBCore records' do
          expect(ability).not_to be_able_to(:access_media_url, public_pbcore_record)
        end

        include_examples 'denies protected and private records'
      end

      context 'when User is not on-site; User is not an AAPB referer; User is not embedding the media; User is an authorized referer' do
        let(:user) { instance_double(User, 'onsite?' => false, 'aapb_referer?' => false, 'embed?' => false, 'authorized_referer?' => true) }

        it 'allows access to public PBCore records' do
          expect(ability).to be_able_to(:access_media_url, public_pbcore_record)
        end

        include_examples 'denies protected and private records'
      end
    end
  end
end

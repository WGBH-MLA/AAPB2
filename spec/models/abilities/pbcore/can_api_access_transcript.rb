require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  # The 'user' is set with let(:user) in the contexts below.
  subject(:ability) { Ability.new(user) }

  context 'for PBCore records with transcripts' do
    let(:public_pbcore_record) { PBCorePresenter.new(File.read('./spec/fixtures/pbcore/access-level-public.xml')) }
    let(:protected_pbcore_record) { PBCorePresenter.new(File.read('./spec/fixtures/pbcore/access-level-protected.xml')) }

    context 'when User is offsite' do
      let(:user) { instance_double(User, 'onsite?' => false) }

      it 'access_transcript returns true for a public record' do
        expect(ability).to be_able_to(:access_transcript, public_pbcore_record)
      end

      it 'access_transcript returns false for a protected record' do
        expect(ability).to_not be_able_to(:access_transcript, protected_pbcore_record)
      end
    end

    context 'when User is onsite' do
      let(:user) { instance_double(User, 'onsite?' => true) }

      it 'access_transcript returns true for a public record' do
        expect(ability).to be_able_to(:access_transcript, public_pbcore_record)
      end

      it 'access_transcript returns false for a protected record' do
        expect(ability).to be_able_to(:access_transcript, protected_pbcore_record)
      end
    end
  end
end

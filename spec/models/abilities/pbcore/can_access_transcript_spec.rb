require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  # The 'user' is set with let(:user) in the contexts below.
  subject(:ability) { Ability.new(user) }

  context 'for PBCore records with transcripts' do
    let(:pbcore_orr_transcript) { PBCore.new(File.read('./spec/fixtures/pbcore/clean-text-transcript.xml')) }
    let(:pbcore_indexing_transcript) { PBCore.new(File.read('./spec/fixtures/pbcore/clean-transcript.xml')) }

    context 'when User is offsite' do
      let(:user) { instance_double(User, 'onsite?' => false, 'aapb_referer?' => false, 'embed?' => false, 'authorized_referer?' => true) }

      it 'access_transcript returns true for an ORR transcript' do
        expect(ability).to be_able_to(:access_transcript, pbcore_orr_transcript)
      end

      it 'access_transcript returns false for an Indexing transcript without public access' do
        expect(ability).to_not be_able_to(:access_transcript, pbcore_indexing_transcript)
      end
    end
  end
end

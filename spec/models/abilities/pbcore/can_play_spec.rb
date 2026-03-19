require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  # The 'user' is set with let(:user) in the contexts below.
  subject(:ability) { Ability.new(user) }

  context 'for PBCore records with transcripts' do
    let(:public_pbcore_record) { PBCorePresenter.new(File.read('./spec/fixtures/pbcore/access-level-public.xml')) }
    let(:protected_pbcore_record) { PBCorePresenter.new(File.read('./spec/fixtures/pbcore/access-level-protected.xml')) }
    let(:private_pbcore_record) { PBCorePresenter.new(File.read('./spec/fixtures/pbcore/access-level-private.xml')) }

    # Tests for onsite user that has not affirmed TOS
    context 'when User is onsite but has not affirmed TOS' do
      let(:user) { instance_double(User, 'onsite?' => true, 'usa?' => true, 'bot?' => false, 'affirmed_tos?' => false, 'authorized_referer?' => false) }

      it 'can play returns false for a public record' do
        expect(ability).not_to be_able_to(:play, public_pbcore_record)
      end

      it 'can play returns false for an Onsite record' do
        expect(ability).not_to be_able_to(:play, protected_pbcore_record)
      end

      it 'can play returns false for a Private record' do
        expect(ability).not_to be_able_to(:play, private_pbcore_record)
      end
    end

    # Tests for onsite user that has affirmed TOS
    context 'when User is onsite but has not affirmed TOS' do
      let(:user) { instance_double(User, 'onsite?' => true, 'usa?' => true, 'bot?' => false, 'affirmed_tos?' => true, 'authorized_referer?' => false) }

      it 'can play returns true for a public record' do
        expect(ability).to be_able_to(:play, public_pbcore_record)
      end

      it 'can play returns true for an Onsite record' do
        expect(ability).to be_able_to(:play, protected_pbcore_record)
      end

      it 'can play returns false for a Private record' do
        expect(ability).not_to be_able_to(:play, private_pbcore_record)
      end
    end

    # Tests for offsite users, but in US
    context 'when User is offsite; User is in the US, User is a bot; User affirmed TOS; User is an authorized referer' do
      let(:user) { instance_double(User, 'onsite?' => false, 'usa?' => true, 'bot?' => true, 'affirmed_tos?' => true, 'authorized_referer?' => true) }

      it 'can play returns false for a public record' do
        expect(ability).not_to be_able_to(:play, public_pbcore_record)
      end

      it 'can play returns false for an On Location record' do
        expect(ability).not_to be_able_to(:play, protected_pbcore_record)
      end

      it 'can play returns false for a Private record' do
        expect(ability).not_to be_able_to(:play, private_pbcore_record)
      end
    end

    context 'when User is offsite; User is in the US, User is a bot; User affirmed TOS; User is not an authorized referer' do
      let(:user) { instance_double(User, 'onsite?' => false, 'usa?' => true, 'bot?' => true, 'affirmed_tos?' => true, 'authorized_referer?' => false) }

      it 'can play returns false for a public record' do
        expect(ability).not_to be_able_to(:play, public_pbcore_record)
      end

      it 'can play returns false for an On Location record' do
        expect(ability).not_to be_able_to(:play, protected_pbcore_record)
      end

      it 'can play returns false for a Private record' do
        expect(ability).not_to be_able_to(:play, private_pbcore_record)
      end
    end

    context 'when User is offsite; User is in the US, User is a bot; User has not affirmed TOS; User is not an authorized referer' do
      let(:user) { instance_double(User, 'onsite?' => false, 'usa?' => true, 'bot?' => true, 'affirmed_tos?' => false, 'authorized_referer?' => false) }

      it 'can play returns false for a public record' do
        expect(ability).not_to be_able_to(:play, public_pbcore_record)
      end

      it 'can play returns false for an On Location record' do
        expect(ability).not_to be_able_to(:play, protected_pbcore_record)
      end

      it 'can play returns false for a Private record' do
        expect(ability).not_to be_able_to(:play, private_pbcore_record)
      end
    end

    context 'when User is offsite; User is in the US, User is not a bot; User has not affirmed TOS; User is not an authorized referer' do
      let(:user) { instance_double(User, 'onsite?' => false, 'usa?' => true, 'bot?' => false, 'affirmed_tos?' => false, 'authorized_referer?' => false) }

      it 'can play returns false for a public record' do
        expect(ability).not_to be_able_to(:play, public_pbcore_record)
      end

      it 'can play returns false for an On Location record' do
        expect(ability).not_to be_able_to(:play, protected_pbcore_record)
      end

      it 'can play returns false for a Private record' do
        expect(ability).not_to be_able_to(:play, private_pbcore_record)
      end
    end

    context 'when User is offsite; User is in the US, User is not a bot; User has affirmed TOS; User is not an authorized referer' do
      let(:user) { instance_double(User, 'onsite?' => false, 'usa?' => true, 'bot?' => false, 'affirmed_tos?' => true, 'authorized_referer?' => false) }

      it 'can play returns true for a public record' do
        expect(ability).to be_able_to(:play, public_pbcore_record)
      end

      it 'can play returns false for an On Location record' do
        expect(ability).not_to be_able_to(:play, protected_pbcore_record)
      end
      it 'can play returns false for a private record' do
        expect(ability).not_to be_able_to(:play, private_pbcore_record)
      end
    end

    context 'when User is offsite; User is in the US, User is not a bot; User has not affirmed TOS; User is an authorized referer' do
      let(:user) { instance_double(User, 'onsite?' => false, 'usa?' => true, 'bot?' => false, 'affirmed_tos?' => false, 'authorized_referer?' => true) }

      it 'can play returns true for a public record' do
        expect(ability).to be_able_to(:play, public_pbcore_record)
      end

      it 'can play returns false for an On Location record' do
        expect(ability).not_to be_able_to(:play, protected_pbcore_record)
      end
      it 'can play returns false for a private record' do
        expect(ability).not_to be_able_to(:play, private_pbcore_record)
      end
    end

    # Tests for offsite users, not in US
    context 'when User is offsite; User is not in the US, User is not a bot; User has not affirmed TOS; User is not an authorized referer' do
      let(:user) { instance_double(User, 'onsite?' => false, 'usa?' => false, 'bot?' => false, 'affirmed_tos?' => false, 'authorized_referer?' => false) }

      it 'can play returns false for a public record' do
        expect(ability).not_to be_able_to(:play, public_pbcore_record)
      end

      it 'can play returns false for an On Location record' do
        expect(ability).not_to be_able_to(:play, protected_pbcore_record)
      end

      it 'can play returns false for a private record' do
        expect(ability).not_to be_able_to(:play, private_pbcore_record)
      end
    end

    context 'when User is offsite; User is not in the US, User is not a bot; User has affirmed TOS; User is not an authorized referer' do
      let(:user) { instance_double(User, 'onsite?' => false, 'usa?' => false, 'bot?' => false, 'affirmed_tos?' => true, 'authorized_referer?' => false) }

      before do
        allow(GlobalMedia).to receive(:allowed?).with(public_pbcore_record.id).and_return(true)
      end

      it 'can play returns true for a globally allowed public record' do
        expect(ability).to be_able_to(:play, public_pbcore_record)
      end

      it 'can play returns false for an On Location record' do
        expect(ability).not_to be_able_to(:play, protected_pbcore_record)
      end

      it 'can play returns false for a private record' do
        expect(ability).not_to be_able_to(:play, private_pbcore_record)
      end
    end

    context 'when User is offsite; User is not in the US, User is not a bot; User has not affirmed TOS; User is not an authorized referer' do
      let(:user) { instance_double(User, 'onsite?' => false, 'usa?' => false, 'bot?' => false, 'affirmed_tos?' => false, 'authorized_referer?' => false) }

      before do
        allow(GlobalMedia).to receive(:allowed?).with(public_pbcore_record.id).and_return(true)
        allow(GlobalMedia).to receive(:allowed?).with(protected_pbcore_record.id).and_return(false)
        allow(GlobalMedia).to receive(:allowed?).with(private_pbcore_record.id).and_return(false)
      end

      it 'can play returns false for a globally allowed public record' do
        expect(ability).not_to be_able_to(:play, public_pbcore_record)
      end

      it 'can play returns false for an On Location record' do
        expect(ability).not_to be_able_to(:play, protected_pbcore_record)
      end

      it 'can play returns false for a private record' do
        expect(ability).not_to be_able_to(:play, private_pbcore_record)
      end
    end
  end
end

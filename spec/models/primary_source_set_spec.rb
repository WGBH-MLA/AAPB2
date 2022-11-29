require_relative '../../app/models/primary_source_set'

describe PrimarySourceSet do
  describe 'correctly configured' do
    class MockPrimarySourceSet < PrimarySourceSet
      ROOT = (Rails.root + 'spec/fixtures/primary_source_sets').to_s
    end

    let(:edu_set) { MockPrimarySourceSet.find_by_path('set') }
    let(:edu_clip) { MockPrimarySourceSet.find_by_path('set/clip') }

    # test any accessor model methods that have specific output expectations, like pdf_link returns a bare url

    describe 'has expected fields' do
      it 'can load set fixture' do
        expect(edu_set.title).to eq("Teacher Teacher")
      end
      it 'can load clip fixture' do
        expect(edu_clip.title).to eq("My Dog Ate It")
      end      
    end

    describe 'is_source_set?' do
      it 'returns true if set' do
        expect(edu_set.is_source_set?).to eq(true)
      end
      it 'returns false if clip' do
        expect(edu_clip.is_source_set?).to eq(false)
      end      
    end

    describe 'other_resources' do
      it 'returns only other sets, none in this test case' do
        expect(edu_clip.other_resources).to eq( [] )
      end
    end

    describe 'clipstart' do
      it 'correct format yields start time' do
        expect(edu_clip.clip_start).to eq(3462)
      end
      it 'correct format yields end time' do
        expect(edu_clip.clip_end).to eq(3474)
      end      
    end

    describe 'guid no cruft' do
      it 'returns plaintext guid' do
        expect(edu_clip.guid).to eq("cpb-aacip-62-5m6251fv96")
      end
    end
  end
end

require_relative '../../app/models/exhibit'

describe EducatorResource do
  describe 'correctly configured' do
    class MockEducatorResource < EducatorResource
      ROOT = (Rails.root + 'spec/fixtures/educator_resources').to_s
    end

    let(:edu_set) { MockEducatorResource.find_by_path('set') }
    let(:edu_clip) { MockEducatorResource.find_by_path('set/clip') }

    # test any accessor model methods that have specific output expectations, like pdf_link returns a bare url

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
        expect(edu_set.other_resources).to eq(EducatorResource("other"))
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
        expect(edu_clip.guid).to eq("cpb-aacip-069-234dkfj")
      end
    end
  end
end

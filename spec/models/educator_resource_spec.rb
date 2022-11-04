require_relative '../../app/models/exhibit'

describe EducatorResource do
  describe 'correctly configured' do
    class MockEducatorResource < EducatorResource
      ROOT = (Rails.root + 'spec/fixtures/educator_resources').to_s
    end

    let(:educator_resource) { MockEducatorResource.find_by_path('set/clip') }


    describe '.authors' do
      it 'returns the authors' do
        expect(exhibit.authors).to eq([
          { img_url: 'https://s3.amazonaws.com/americanarchive.org/exhibits/assets/author2.png',
            title: 'Curator Extraordinaire',
            name: 'First Author' },
          { img_url: 'https://s3.amazonaws.com/americanarchive.org/exhibits/assets/author.png',
            title: 'Second Banana',
            name: 'Second Author' }
        ])
      end
    end

    describe '.subsection?' do
      it 'returns true if parent' do
        expect(exhibit.subsection?).to eq(true)
      end
    end

    describe '.top_title' do
      it 'returns the top title' do
        expect(exhibit.top_title).to eq('Parent!')
      end
    end

    describe '.top_path' do
      it 'returns the top_path' do
        expect(exhibit.top_path).to eq('parent')
      end
    end

    describe 'not found handling' do
      it 'returns nil for bad paths' do
        expect(MockExhibit.find_by_path('no/such/path')).to eq(nil)
      end
    end
  end
end

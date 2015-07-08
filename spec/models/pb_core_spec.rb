require_relative '../../app/models/validated_pb_core'

describe 'Validated and plain PBCore' do
  pbc_xml = File.read('spec/fixtures/pbcore/clean-MOCK.xml')

  describe ValidatedPBCore do
    describe 'valid docs' do
      Dir['spec/fixtures/pbcore/clean-*.xml'].each do |path|
        it "accepts #{File.basename(path)}" do
          expect { ValidatedPBCore.new(File.read(path)) }.not_to raise_error
        end
      end
    end

    describe 'invalid docs' do
      it 'rejects missing closing brace' do
        invalid_pbcore = pbc_xml.sub(/>\s*$/, '')
        expect { ValidatedPBCore.new(invalid_pbcore) }.to(
          raise_error(/missing tag start/))
      end

      it 'rejects missing closing tag' do
        invalid_pbcore = pbc_xml.sub(/<\/[^>]+>\s*$/, '')
        expect { ValidatedPBCore.new(invalid_pbcore) }.to(
          raise_error(/Missing end tag/))
      end

      it 'rejects missing namespace' do
        invalid_pbcore = pbc_xml.sub(/xmlns=['"][^'"]+['"]/, '')
        expect { ValidatedPBCore.new(invalid_pbcore) }.to(
          raise_error(/Element 'pbcoreDescriptionDocument': No matching global declaration/))
      end

      it 'rejects unknown media types at creation' do
        invalid_pbcore = pbc_xml.gsub(
          /<instantiationMediaType>[^<]+<\/instantiationMediaType>/,
          '<instantiationMediaType>unexpected</instantiationMediaType>')
        expect { ValidatedPBCore.new(invalid_pbcore) }.to(
          raise_error(/Unexpected media types: \["unexpected"\]/))
      end
    end
  end

  describe PBCore do
    describe 'empty' do
      empty_pbc = PBCore.new('<pbcoreDescriptionDocument/>')

      it '"other" if no media_type' do
        expect(empty_pbc.media_type).to eq('other')
      end

      it 'nil if no asset_type' do
        expect(empty_pbc.asset_type).to eq(nil)
      end
    end

    describe 'full' do
      pbc = PBCore.new(pbc_xml)

      assertions = {
        to_solr: {
          'id' => '1234',
          'xml' => pbc_xml,
          'episode_number_titles' => ['3-2-1'],
          'episode_titles' => ['Kaboom!'],
          'program_titles' => ['Gratuitous Explosions'],
          'series_titles' => ['Nova'],
          'text' => [ #
            'Best episode ever!', 'Call-in', 'Music', #
            'explosions -- gratuitious', 'musicals -- horror', #
            'Curly', 'bald', 'Stooges', 'Larry', 'balding', 'Moe', 'hair', #
            'Copy Left: All rights reversed.', #
            'Album', 'Uncataloged', '2000-01-01', #
            'Episode Number', '3-2-1', 'Episode', 'Kaboom!', #
            'Program', 'Gratuitous Explosions', 'Series', 'Nova', '1234', #
            'AAPB ID', 'somewhere else', '5678', #
            'WGBH', 'Boston', 'Massachusetts', #
            'Moving Image', '1:23:45'],
          'titles' => ['3-2-1', 'Kaboom!', 'Gratuitous Explosions', 'Nova'],
          'title' => 'Nova -- Gratuitous Explosions -- Kaboom! -- 3-2-1',
          'contribs' => ['Larry', 'Stooges', 'Curly', 'Stooges', 'Moe', 'Stooges'],
          'year' => '2000',
          'exhibits' => [],
          'media_type' => 'Moving Image',
          'genres' => ['Call-in'],
          'topics' => ['Music'],
          'asset_type' => 'Album',
          'organization' => 'WGBH (MA)',
          'access_types' => ['All', 'Digitized']
        },
        access_types: ['All', 'Digitized'],
        asset_type: 'Album',
        asset_date: '2000-01-01',
        asset_dates: [['Uncataloged', '2000-01-01']],
        titles_sort: 'Nova -- Gratuitous Explosions -- Kaboom! -- 3-2-1',
        titles: [['Episode Number', '3-2-1'], ['Episode', 'Kaboom!'], #
                 ['Program', 'Gratuitous Explosions'], ['Series', 'Nova']],
        title: 'Kaboom!',
        exhibits: [],
        descriptions: ['Best episode ever!'],
        instantiations: [PBCore::Instantiation.new('Moving Image', 'should be ignored!'),
                         PBCore::Instantiation.new('Moving Image', '1:23:45')],
        rights_summary: 'Copy Left: All rights reversed.',
        genres: ['Call-in'],
        topics: ['Music'],
        id: '1234',
        ids: [['AAPB ID', '1234'], ['somewhere else', '5678']],
        ci_ids: ['a-32-digit-hex', 'another-32-digit-hex'],
        media_srcs: ["/media/1234?part=1", "/media/1234?part=2"],
        img_src: 'http://mlamedia01.wgbh.org/aapb/thumbnail/1234.jpg',
        organization_pbcore_name: 'WGBH',
        organization: Organization.find_by_pbcore_name('WGBH'),        
        organization_state_abbreviation: 'MA',
        rights_code: 'PUBLIC',
        media_type: 'Moving Image',
        video?: true,
        audio?: false,
        duration: '1:23:45',
        digitized?: true,
        subjects: ['explosions -- gratuitious', 'musicals -- horror'],
        creators: [PBCore::NameRoleAffiliation.new('creator', 'Larry', 'balding', 'Stooges')],
        contributors: [PBCore::NameRoleAffiliation.new('contributor', 'Curly', 'bald', 'Stooges')],
        publishers: [PBCore::NameRoleAffiliation.new('publisher', 'Moe', 'hair', 'Stooges')]
      }

      assertions.each do |method, value|
        it "\##{method} works" do
          expect(pbc.send(method)).to eq(value)
        end
      end

      it 'tests everthing' do
        expect(assertions.keys.sort).to eq(PBCore.instance_methods(false).sort)
      end
    end
  end
end

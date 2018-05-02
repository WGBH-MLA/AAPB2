require 'json'
require_relative '../../lib/aapb'
require_relative '../../app/models/validated_pb_core'
require_relative '../../app/models/caption_file'

describe 'Validated and plain PBCore' do
  pbc_xml = File.read('spec/fixtures/pbcore/clean-MOCK.xml')

  let(:pbc_json_transcript) { File.read('spec/fixtures/pbcore/clean-exhibit.xml') }
  let(:pbc_text_transcript) { File.read('spec/fixtures/pbcore/clean-text-transcript.xml') }
  let(:pbc_supplemental_materials) { File.read('spec/fixtures/pbcore/clean-supplemental-materials.xml') }
  let(:pbc_16_9) { File.read('spec/fixtures/pbcore/clean-16-9.xml') }
  let(:pbc_multi_org) { File.read('spec/fixtures/pbcore/clean-multiple-orgs.xml') }
  let(:playlist_1) { File.read('spec/fixtures/pbcore/clean-playlist-1.xml') }
  let(:playlist_2) { File.read('spec/fixtures/pbcore/clean-playlist-2.xml') }
  let(:playlist_3) { File.read('spec/fixtures/pbcore/clean-playlist-3.xml') }

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

      it 'rejects multi "Level of User Access"' do
        invalid_pbcore = pbc_xml.sub(
          /<pbcoreAnnotation/,
          "<pbcoreAnnotation annotationType='Level of User Access'>On Location</pbcoreAnnotation><pbcoreAnnotation")
        expect { ValidatedPBCore.new(invalid_pbcore) }.to(
          raise_error(/Should have at most 1 "Level of User Access" annotation/))
      end

      it 'rejects digitized w/o "Level of User Access"' do
        invalid_pbcore = pbc_xml.gsub(
          /<pbcoreAnnotation annotationType='Level of User Access'>[^<]+<[^>]+>/,
          '')
        expect { ValidatedPBCore.new(invalid_pbcore) }.to(
          raise_error(/Should have "Level of User Access" annotation if digitized/))
      end

      it 'rejects undigitized w/ "Level of User Access"' do
        invalid_pbcore = pbc_xml.gsub(
          /<pbcoreIdentifier source='Sony Ci'>[^<]+<[^>]+>/,
          '')
        expect { ValidatedPBCore.new(invalid_pbcore) }.to(
          raise_error(/Should not have "Level of User Access" annotation if not digitized/))
      end

      it 'rejects "Outside URL" if not explicitly ORR' do
        invalid_pbcore = pbc_xml.gsub( # First make it un-digitized
          /<pbcoreIdentifier source='Sony Ci'>[^<]+<[^>]+>/,
          '').gsub( # Then remove access
            /<pbcoreAnnotation annotationType='Level of User Access'>[^<]+<[^>]+>/,
            '')
        expect { ValidatedPBCore.new(invalid_pbcore) }.to(
          raise_error(/If there is an Outside URL, the record must be explicitly public/))
      end
    end
  end

  describe PBCore do
    it 'SRT on S3 matches fixture' do
      # Rather than mocking more of it up, the ingest test really pulls an SRT from S3.
      # ... but we still want to make sure that that SRT before it is cleaned has the data we expect.

      # Ruby defaults to read files as UTF-8,
      # but the file delivered over the network is seen as ASCII: not sure what determines that.
      expect(File.open(Rails.root + 'spec/fixtures/captions/srt/1234.srt1.srt', 'r:' + Encoding::ASCII_8BIT.to_s).read)
        .to eq('' + Net::HTTP.get_response(URI.parse('https://s3.amazonaws.com/americanarchive.org/captions/1234/1234.srt1.srt')).body)
    end

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
      assertions = {
        to_solr: {
          'id' => '1234',
          'xml' => pbc_xml,
          'episode_number_titles' => ['3-2-1'],
          'episode_titles' => ['Kaboom!'],
          'program_titles' => ['Gratuitous Explosions'],
          'series_titles' => ['Nova'],
          'special_collection' => nil,
          'text' => ['1234', '1:23:45', '2000-01-01', '3-2-1', '5678', 'AAPB ID',
                     'Album', 'Best episode ever!', 'Boston', 'Call-in', 'Copy Left: All rights reversed.', 'Copy Right: Reverse all rights.',
                     'Curly', 'Date', 'Episode', 'Episode Number', 'Gratuitous Explosions',
                     'Kaboom!', 'Larry', 'Massachusetts', 'Moe', 'Moving Image', 'Music',
                     'Nova', 'Program', 'Series', 'Stooges', 'WGBH', 'bald', 'balding', 'explosions -- gratuitious',
                     'hair', 'musicals -- horror', 'somewhere else',
                     "Raw bytes 0-255 follow: !\"\#$%&'()*+,-./0123456789:;<=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ "],
          'titles' => ['Nova', 'Gratuitous Explosions', '3-2-1', 'Kaboom!'],
          'title' => 'Nova; Gratuitous Explosions; 3-2-1; Kaboom!',
          'contribs' => %w(Larry Stooges Curly Stooges Moe Stooges),
          'year' => '2000',
          'exhibits' => [],
          'media_type' => 'Moving Image',
          'genres' => ['Call-in'],
          'topics' => ['Music'],
          'asset_type' => 'Album',
          'organizations' => ['WGBH (MA)'],
          'playlist_group' => nil,
          'playlist_order' => 0,
          'states' => ['Massachusetts'],
          'access_types' => [PBCore::ALL_ACCESS, PBCore::PUBLIC_ACCESS, PBCore::DIGITIZED_ACCESS]
          # TODO: UI will transform internal representation.
        },
        access_types: [PBCore::ALL_ACCESS, PBCore::PUBLIC_ACCESS, PBCore::DIGITIZED_ACCESS],
        access_level: 'Online Reading Room',
        asset_type: 'Album',
        asset_date: '2000-01-01',
        asset_dates: [['Date', '2000-01-01']],
        titles: [%w(Series Nova), ['Program', 'Gratuitous Explosions'], #
                 ['Episode Number', '3-2-1'], ['Episode', 'Kaboom!']],
        title: 'Nova; Gratuitous Explosions; 3-2-1; Kaboom!',
        special_collection: nil,
        exhibits: [],
        descriptions: ['Best episode ever!'],
        instantiations: [PBCoreInstantiation.new('Moving Image', 'should be ignored!'),
                         PBCoreInstantiation.new('Moving Image', '1:23:45')],
        rights_summaries: ['Copy Left: All rights reversed.', 'Copy Right: Reverse all rights.'],
        genres: ['Call-in'],
        topics: ['Music'],
        id: '1234',
        ids: [['AAPB ID', '1234'], ['somewhere else', '5678']],
        display_ids: [['AAPB ID', '1234']],
        ci_ids: ['a-32-digit-hex', 'another-32-digit-hex'],
        media_srcs: ['/media/1234?part=1', '/media/1234?part=2'],
        img_height: 225,
        img_src: "#{AAPB::S3_BASE}/thumbnail/1234.jpg",
        img_width: 300,
        captions_src: 'https://s3.amazonaws.com/americanarchive.org/captions/1234/1234.srt1.srt',
        # rubocop:disable LineLength
        # Doing this because the CaptionFile associated with this PB Core fixture is suspect at best and don't have time to change everywhere it is used.
        transcript_content: "{\"language\":\"en-US\",\"parts\":[{\"text\":\"Raw bytes 0-255 follow: \\u0000\\u0001\\u0002\\u0003\\u0004\\u0005\\u0006\\u0007\\b \\u000e\\u000f\\u0010\\u0011\\u0012\\u0013\\u0014\\u0015\\u0016\\u0017\\u0018\\u0019\\u001a\\u001b\\u001c\\u001d\\u001e\\u001f !\\\"\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\u007F\u0080\u0081\u0082\u0083\u0084\u0086\u0087\u0088\u0089\u008A\u008B\u008C\u008D\u008E\u008F\u0090\u0091\u0092\u0093\u0094\u0095\u0096\u0097\u0098\u0099\u009A\u009B\u009C\u009D\u009E\u009F ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ\",\"start_time\":\"0.0\",\"end_time\":\"20.0\"}]}",
        # rubocop:enable LineLength
        transcript_src: nil,
        transcript_status: nil,
        outside_url: 'http://www.wgbh.org/',
        player_aspect_ratio: '4:3',
        player_specs: %w(680 510),
        playlist_group: nil,
        playlist_map: nil,
        playlist_next_id: nil,
        playlist_order: 0,
        playlist_prev_id: nil,
        reference_urls: ['http://www.wgbh.org/'],
        private?: false,
        protected?: false,
        public?: true,
        access_level_description: 'Online Reading Room',
        media_type: 'Moving Image',
        video?: true,
        audio?: false,
        duration: '1:23:45',
        digitized?: true,
        subjects: ['explosions -- gratuitious', 'musicals -- horror'],
        supplemental_content: [],
        creators: [PBCoreNameRoleAffiliation.new('creator', 'Larry', 'balding', 'Stooges')],
        contributors: [PBCoreNameRoleAffiliation.new('contributor', 'Curly', 'bald', 'Stooges')],
        publishers: [PBCoreNameRoleAffiliation.new('publisher', 'Moe', 'hair', 'Stooges')],
        organization_names: ['WGBH'],
        organizations_facet: ['WGBH (MA)'],
        organization_names_display: ['WGBH'],
        organization_objects: [Organization.find_by_pbcore_name('WGBH')],
        states: ['Massachusetts']
      }

      pbc = PBCore.new(pbc_xml)

      assertions.each do |method, value|
        it "\##{method} method works" do
          expect(pbc.send(method)).to eq(value)
        end
      end

      it 'tests everthing' do
        expect(assertions.keys.sort).to eq(PBCore.instance_methods(false).sort)
      end
    end

    describe 'PB Core document with transcript' do
      it 'has expected transcript attributes' do
        pbc = PBCore.new(pbc_json_transcript)
        expected_attrs = {
          'id' => 'cpb-aacip_111-21ghx7d6',
          'player_aspect_ratio' => '4:3',
          'player_specs' => %w(680 510),
          'transcript_status' => 'Online Reading Room Transcript'
        }
        attrs = {
          'id' => pbc.id,
          'player_aspect_ratio' => pbc.player_aspect_ratio,
          'player_specs' => pbc.player_specs,
          'transcript_status' => pbc.transcript_status
        }

        expect(expected_attrs).to eq(attrs)
      end

      it 'returns the expected transcript_content for text transcript' do
        pbc = PBCore.new(pbc_text_transcript)
        expect(pbc.transcript_content).to include(File.read(Rails.root.join('spec', 'fixtures', 'transcripts', 'cpb-aacip-507-0000000j8w-transcript.txt')))
      end

      it 'returns the expected transcript_content for json transcript' do
        pbc = PBCore.new(pbc_json_transcript)
        expect(JSON.parse(pbc.transcript_content)).to include(JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'transcripts', 'cpb-aacip-111-21ghx7d6-transcript.json'))))
      end
    end

    describe 'PB Core document with supplemental materials' do
      it 'returns an array of supplemental materials' do
        pbc = PBCore.new(pbc_supplemental_materials)
        expect(pbc.supplemental_content).to eq([['https://s3.amazonaws.com/americanarchive.org/supplemental-materials/cpb-aacip-509-6h4cn6zm21.pdf', 'Production Transcript']])
      end
    end

    describe 'PB Core document with 16:9 video' do
      it 'has expected 16:9 attributes' do
        pbc = PBCore.new(pbc_16_9)
        expected_attrs = {
          'id' => 'cpb-aacip_508-g44hm5390k',
          'player_aspect_ratio' => '16:9',
          'player_specs' => %w(680 383)
        }

        attrs = {
          'id' => pbc.id,
          'player_aspect_ratio' => pbc.player_aspect_ratio,
          'player_specs' => pbc.player_specs
        }

        expect(expected_attrs).to eq(attrs)
      end
    end

    describe 'PB Core records in playlists' do
      it 'first record has expected attributes' do
        pbc = PBCore.new(playlist_1)
        expected_attrs = {
          'id' => 'cpb-aacip_512-gx44q7rk20',
          'playlist_group' => 'nixonimpeachmentday2',
          'playlist_order' => 1,
          'playlist_next_id' => 'cpb-aacip_512-0r9m32nw1x',
          'playlist_prev_id' => nil
        }

        attrs = {
          'id' => pbc.id,
          'playlist_group' => pbc.playlist_group,
          'playlist_order' => pbc.playlist_order,
          'playlist_next_id' => pbc.playlist_next_id,
          'playlist_prev_id' => pbc.playlist_prev_id
        }

        expect(expected_attrs).to eq(attrs)
      end

      it 'middle record has expected attributes' do
        pbc = PBCore.new(playlist_2)
        expected_attrs = {
          'playlist_group' => 'nixonimpeachmentday2',
          'playlist_order' => 2,
          'playlist_next_id' => 'cpb-aacip_512-w66930pv96',
          'playlist_prev_id' => 'cpb-aacip_512-gx44q7rk20'
        }

        attrs = {
          'playlist_group' => pbc.playlist_group,
          'playlist_order' => pbc.playlist_order,
          'playlist_next_id' => pbc.playlist_next_id,
          'playlist_prev_id' => pbc.playlist_prev_id
        }

        expect(expected_attrs).to eq(attrs)
      end

      it 'last record has expected attributes' do
        pbc = PBCore.new(playlist_3)
        expected_attrs = {
          'playlist_group' => 'nixonimpeachmentday2',
          'playlist_order' => 3,
          'playlist_next_id' => nil,
          'playlist_prev_id' => 'cpb-aacip_512-0r9m32nw1x'
        }

        attrs = {
          'playlist_group' => pbc.playlist_group,
          'playlist_order' => pbc.playlist_order,
          'playlist_next_id' => pbc.playlist_next_id,
          'playlist_prev_id' => pbc.playlist_prev_id
        }

        expect(expected_attrs).to eq(attrs)
      end
    end

    describe 'pbcore object with multiple organizations and states' do
      it 'returns multiple organizations and states' do
        pbc = PBCore.new(pbc_multi_org)

        expected_attrs = {
          'organization_names' => ['Library of Congress', 'KQED'],
          'organizations_facet' => ['Library of Congress (DC)', 'KQED (CA)'],
          'organization_objects' => [Organization.find_by_pbcore_name('Library of Congress'), Organization.find_by_pbcore_name('KQED')],
          'states' => ['District of Columbia', 'California']
        }

        attrs = {
          'organization_names' => pbc.organization_names,
          'organizations_facet' => pbc.organizations_facet,
          'organization_objects' => pbc.organization_objects,
          'states' => pbc.states
        }

        expect(expected_attrs).to eq(attrs)
      end
    end
  end
end

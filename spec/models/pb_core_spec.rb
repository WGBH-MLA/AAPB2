require 'json'
require 'rails_helper'
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
  let(:pbc_multiple_series_with_episodes) { File.read('spec/fixtures/pbcore/clean-multiple-series-with-episode-titles.xml') }
  let(:pbc_multiple_episodes_one_series) { File.read('spec/fixtures/pbcore/clean-multiple-episode-numbers-one-series.xml') }
  let(:pbc_alternative_title) { File.read('spec/fixtures/pbcore/clean-alternative-title.xml') }

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

  describe PBCorePresenter do
    let(:pbc) { PBCorePresenter.new(pbc_xml) }

    it 'SRT on S3 matches fixture' do
      # Rather than mocking more of it up, the ingest test really pulls an SRT from S3.
      # ... but we still want to make sure that that SRT before it is cleaned has the data we expect.

      # Ruby defaults to read files as UTF-8,
      # but the file delivered over the network is seen as ASCII: not sure what determines that.
      expect(File.open(Rails.root + 'spec/fixtures/captions/srt/1234.srt1.srt', 'r:' + Encoding::ASCII_8BIT.to_s).read)
        .to eq('' + Net::HTTP.get_response(URI.parse('https://s3.amazonaws.com/americanarchive.org/captions/1234/1234.srt1.srt')).body)
    end

    describe 'empty' do
      empty_pbc = PBCorePresenter.new('<pbcoreDescriptionDocument/>')

      it '"other" if no media_type' do
        expect(empty_pbc.media_type).to eq('other')
      end

      it 'nil if no asset_type' do
        expect(empty_pbc.asset_type).to eq(nil)
      end
    end

    describe '.to_solr' do
      it 'constructs values for solr_document from pbcore xml' do
        expect(pbc.to_solr).to eq(
          'id' => '1234',
          'xml' => pbc_xml,
          'episode_number_titles' => ['3-2-1'],
          'episode_number_sort' => '3-2-1',
          'episode_titles' => ['Kaboom!'],
          'program_titles' => ['Gratuitous Explosions'],
          'series_titles' => ['Nova'],
          'special_collections' => [],
          'text' => [
            '1234', '1:23:45', '2000-01-01', '3-2-1', '5678', 'AAPB ID', 'Album', 'Best episode ever!', 'Boston', 'Call-in', 'Copy Left: All rights reversed.', 'Copy Right: Reverse all rights.', 'Curly', 'Date', 'Episode', 'Episode Number', 'Gratuitous Explosions', 'Kaboom!', 'Larry', 'Massachusetts', 'Moe', 'Moving Image', 'Music', 'Nova', 'Producing Organization', 'Program', 'Series', 'Stooges', 'WGBH', 'bald', 'balding', 'explosions -- gratuitious', 'hair', 'musicals -- horror', 'somewhere else', "Raw bytes 0-255 follow: !\"\#$%&'()*+,-./0123456789:;<=?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~ "],
          'titles' => ['Nova', 'Gratuitous Explosions', '3-2-1', 'Kaboom!'],
          'title' => 'Nova; Gratuitous Explosions; 3-2-1; Kaboom!',
          'contribs' => %w(Larry WGBH Stooges Stooges Curly Stooges Moe Stooges),
          'year' => '2000',
          'exhibits' => [],
          'media_type' => 'Moving Image',
          'genres' => ['Call-in'],
          'topics' => ['Music'],
          'asset_type' => 'Album',
          'contributing_organizations' => ['WGBH (MA)'],
          'playlist_group' => nil,
          'playlist_order' => 0,
          'producing_organizations' => ['WGBH'],
          'states' => ['Massachusetts'],
          'access_types' => [PBCorePresenter::ALL_ACCESS, PBCorePresenter::PUBLIC_ACCESS, PBCorePresenter::DIGITIZED_ACCESS],
          'asset_date' => '2000-01-01T00:00:00Z'
        )
      end
    end

    describe '.access_types' do
      it 'returns the access_types from pbcore xml' do
        expect(pbc.access_types).to eq([PBCorePresenter::ALL_ACCESS, PBCorePresenter::PUBLIC_ACCESS, PBCorePresenter::DIGITIZED_ACCESS])
      end
    end

    describe '.access_level' do
      it 'returns the access_level from pbcore xml' do
        expect(pbc.access_level).to eq('Online Reading Room')
      end
    end

    describe '.asset_type' do
      it 'returns the asset_type from the pbcore xml' do
        expect(pbc.asset_type).to eq('Album')
      end
    end

    describe '.asset_date' do
      it 'returns the asset_date from the pbcore xml' do
        expect(pbc.asset_date).to eq('2000-01-01')
      end
    end

    describe '.asset_dates' do
      it 'returns the asset_dates from the pbcore xml' do
        expect(pbc.asset_dates).to eq([['Date', '2000-01-01']])
      end
    end

    describe '.titles' do
      it 'returns the titles from the pbcore xml' do
        expect(pbc.titles).to eq([%w(Series Nova), ['Program', 'Gratuitous Explosions'], ['Episode Number', '3-2-1'], ['Episode', 'Kaboom!']])
      end
    end

    describe '.title' do
      it 'returns the title from the pbcore xml' do
        expect(pbc.title).to eq('Nova; Gratuitous Explosions; 3-2-1; Kaboom!')
      end
    end

    describe '.episode_number_sort' do
      it 'returns the episode number from the pbcore xml' do
        expect(pbc.episode_number_sort).to eq('3-2-1')
      end
    end

    describe '.descriptions' do
      it 'returns the descriptions from the pbcore xml' do
        expect(pbc.descriptions).to eq(['Best episode ever!'])
      end
    end

    describe '.instantiations' do
      it 'returns the instantiations from the pbcore xml' do
        expect(pbc.instantiations).to eq([
          PBCoreInstantiation.new('Moving Image', 'should be ignored!'),
          PBCoreInstantiation.new('Moving Image', '1:23:45'),
          PBCoreInstantiation.new('Moving Image', 'should be ignored!')
        ])
      end
    end

    describe '.instantiations_display' do
      it 'returns the instantiations_display from the pbcore xml' do
        expect(pbc.instantiations_display).to eq([
          PBCoreInstantiation.new('Moving Image', 'should be ignored!'),
          PBCoreInstantiation.new('Moving Image', '1:23:45')
        ])
      end
    end

    describe '.rights_summaries' do
      it 'returns the rights_summaries from the pbcore xml' do
        expect(pbc.rights_summaries).to eq(['Copy Left: All rights reversed.', 'Copy Right: Reverse all rights.'])
      end
    end

    describe '.licensing_info' do
      it 'returns the licensing info from the pbcore xml' do
        expect(pbc.licensing_info).to eq('You totally want to license this.')
      end
    end

    describe '.genres' do
      it 'returns the genres from the pbcore xml' do
        expect(pbc.genres).to eq(['Call-in'])
      end
    end

    describe '.topics' do
      it 'returns the topics from the pbcore xml' do
        expect(pbc.topics).to eq(['Music'])
      end
    end

    describe '.id' do
      it 'returns the id from the pbcore xml' do
        expect(pbc.id).to eq('1234')
      end
    end

    describe '.ids' do
      it 'returns the ids from the pbcore xml' do
        expect(pbc.ids).to eq([['AAPB ID', '1234'], ['somewhere else', '5678']])
      end
    end

    describe '.display_ids' do
      it 'returns the display ids from the pbcore xml' do
        expect(pbc.display_ids).to eq([['AAPB ID', '1234']])
      end
    end

    describe '.ci_ids' do
      it 'returns sony ci ids from the pbcore xml' do
        expect(pbc.ci_ids).to eq(['a-32-digit-hex', 'another-32-digit-hex'])
      end
    end

    describe '.media_srcs' do
      it 'returns the media srcs from the pbcore xml' do
        expect(pbc.media_srcs).to eq(['/media/1234?part=1', '/media/1234?part=2'])
      end
    end

    describe '.img_height' do
      it 'returns the image height from the pbcore xml' do
        expect(pbc.img_height).to eq(225)
      end
    end

    describe '.img_src' do
      it 'returns the image src from the pbcore xml' do
        expect(pbc.img_src).to eq("#{AAPB::S3_BASE}/thumbnail/1234.jpg")
      end
    end

    describe '.img_width' do
      it 'returns the image width from the pbcore xml' do
        expect(pbc.img_width).to eq(300)
      end
    end

    describe '.captions_src' do
      it 'returns the captions src from the pbcore xml' do
        expect(pbc.captions_src).to eq('https://s3.amazonaws.com/americanarchive.org/captions/1234/1234.srt1.srt')
      end
    end

    describe '.transcript_content' do
      it 'returns the transcript content from the pbcore xml' do
        expect(pbc.transcript_content).to eq("{\"language\":\"en-US\",\"parts\":[{\"text\":\"Raw bytes 0-255 follow: \\u0000\\u0001\\u0002\\u0003\\u0004\\u0005\\u0006\\u0007\\b \\u000e\\u000f\\u0010\\u0011\\u0012\\u0013\\u0014\\u0015\\u0016\\u0017\\u0018\\u0019\\u001a\\u001b\\u001c\\u001d\\u001e\\u001f !\\\"\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\u007F\u0080\u0081\u0082\u0083\u0084\u0086\u0087\u0088\u0089\u008A\u008B\u008C\u008D\u008E\u008F\u0090\u0091\u0092\u0093\u0094\u0095\u0096\u0097\u0098\u0099\u009A\u009B\u009C\u009D\u009E\u009F ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ\",\"start_time\":\"0.0\",\"end_time\":\"20.0\"}]}")
      end
    end

    describe '.transcript_src' do
      it 'returns the transcript src from the pbcore xml' do
        expect(pbc.transcript_src).to eq('notarealurl')
      end
    end

    describe '.outside_url' do
      it 'returns the outside url from the pbcore xml' do
        expect(pbc.outside_url).to eq('http://www.wgbh.org/')
      end
    end

    describe '.player_aspect_ratio' do
      it 'returns the player aspect ratio from the pbcore xml' do
        expect(pbc.player_aspect_ratio).to eq('4:3')
      end
    end

    describe '.player_specs' do
      it 'returns the player specs from the pbcore xml' do
        expect(pbc.player_specs).to eq(%w(680 510))
      end
    end

    describe '.reference_urls' do
      it 'returns the refernce urls from the pbcore xml' do
        expect(pbc.reference_urls).to eq(['http://www.wgbh.org/'])
      end
    end

    describe '.private?' do
      it 'returns whether the media is available at all on the site from pbcore xml' do
        expect(pbc.private?).to eq(false)
      end
    end

    describe '.producing_organizations' do
      it 'returns the producing organizations from the pbcore xml' do
        expect(pbc.producing_organizations).to eq([PBCoreNameRoleAffiliation.new('creator', 'WGBH', 'Producing Organization', 'Stooges')])
      end
    end

    describe '.prodcing_organizations_facet' do
      it 'returns the producing organization facet name from the pbcore xml' do
        expect(pbc.producing_organizations_facet).to eq(['WGBH'])
      end
    end

    describe '.protected?' do
      it 'returns whether the media is available on site from pbcore xml' do
        expect(pbc.protected?).to eq(false)
      end
    end

    describe '.public?' do
      it 'returns whether the media is always available on the site from pbcore xml' do
        expect(pbc.public?).to eq(true)
      end
    end

    describe '.access_level_description' do
      it 'returns the access level description from the pbcore xml' do
        expect(pbc.access_level_description).to eq('Online Reading Room')
      end
    end

    describe '.media_type' do
      it 'returns the media_type from the pbcore xml' do
        expect(pbc.media_type).to eq('Moving Image')
      end
    end

    describe '.video?' do
      it 'returns whether the pbcore xml represents a video' do
        expect(pbc.video?).to eq(true)
      end
    end

    describe '.audio?' do
      it 'returns whether the pbcore xml represents audio' do
        expect(pbc.audio?).to eq(false)
      end
    end

    describe '.duration' do
      it 'returns the duration from the the pbcore xml' do
        expect(pbc.duration).to eq('1:23:45')
      end
    end

    describe '.digitized?' do
      it 'returns whether the pbcore xml represents a digitized media object' do
        expect(pbc.digitized?).to eq(true)
      end
    end

    describe '.subjects' do
      it 'returns the subjects from the pbcore xml' do
        expect(pbc.subjects).to eq(['explosions -- gratuitious', 'musicals -- horror'])
      end
    end

    describe '.creators' do
      it 'returns the creators from the pbcore xml' do
        expect(pbc.creators).to eq([PBCoreNameRoleAffiliation.new('creator', 'Larry', 'balding', 'Stooges'), PBCoreNameRoleAffiliation.new('creator', 'WGBH', 'Producing Organization', 'Stooges')])
      end
    end

    describe '.contributors' do
      it 'returns the contributors from the pbcore xml' do
        expect(pbc.contributors).to eq([PBCoreNameRoleAffiliation.new('contributor', 'Curly', 'bald', 'Stooges')])
      end
    end

    describe '.publishers' do
      it 'returns the publishers from the pbcore xml' do
        expect(pbc.publishers).to eq([PBCoreNameRoleAffiliation.new('publisher', 'Moe', 'hair', 'Stooges')])
      end
    end

    describe '.contributing_organization_names' do
      it 'returns the contributing_organization_names from the pbcore xml' do
        expect(pbc.contributing_organization_names).to eq(['WGBH', 'American Archive of Public Broadcasting'])
      end
    end

    describe '.contributing_organizations_facet' do
      it 'returns the contributing organization facet names from the pbcore xml' do
        expect(pbc.contributing_organizations_facet).to eq(['WGBH (MA)'])
      end
    end

    describe '.contributing_organization_names_display' do
      it 'returns the contributing organization display names from the pbcore xml' do
        expect(pbc.contributing_organization_names_display).to eq(['WGBH'])
      end
    end

    describe '.contributing_organization_objects' do
      it 'returns the contributing organization object from the pbcore xml' do
        expect(pbc.contributing_organization_objects).to eq([Organization.find_by_pbcore_name('WGBH')])
      end
    end

    describe '.states' do
      it 'returns the organization states from the pbcore xml' do
        expect(pbc.states).to eq(['Massachusetts'])
      end
    end

    describe '.img?' do
      it 'returns whether a display image is available for the media from the pbcore xml' do
        expect(pbc.img?).to eq(true)
      end
    end

    describe '.all_parties' do
      it 'returns all the orgs involved in production from the pbcore xml' do
        expect(pbc.all_parties).to eq([
          PBCoreNameRoleAffiliation.new('creator', 'WGBH', 'Producing Organization', 'Stooges'),
          PBCoreNameRoleAffiliation.new('contributor', 'Curly', 'bald', 'Stooges'),
          PBCoreNameRoleAffiliation.new('creator', 'Larry', 'balding', 'Stooges'),
          PBCoreNameRoleAffiliation.new('publisher', 'Moe', 'hair', 'Stooges')
        ])
      end
    end

    describe 'PB Core document with transcript' do
      it 'has expected transcript attributes' do
        pbc = PBCorePresenter.new(pbc_json_transcript)
        expected_attrs = {
          'id' => 'cpb-aacip_111-21ghx7d6',
          'player_aspect_ratio' => '4:3',
          'player_specs' => %w(680 510),
          'transcript_status' => 'Correct'
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
        pbc = PBCorePresenter.new(pbc_text_transcript)
        expect(pbc.transcript_content).to include(File.read(Rails.root.join('spec', 'fixtures', 'transcripts', 'cpb-aacip-507-0000000j8w-transcript.txt')))
      end

      it 'returns the expected transcript_content for json transcript' do
        pbc = PBCorePresenter.new(pbc_json_transcript)
        expect(JSON.parse(pbc.transcript_content)).to include(JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'transcripts', 'cpb-aacip-111-21ghx7d6-transcript.json'))))
      end
    end

    describe 'PB Core document with supplemental materials' do
      it 'returns an array of supplemental materials' do
        pbc = PBCorePresenter.new(pbc_supplemental_materials)
        expect(pbc.supplemental_content).to eq([['https://s3.amazonaws.com/americanarchive.org/supplemental-materials/cpb-aacip-509-6h4cn6zm21.pdf', 'Production Transcript']])
      end
    end

    describe 'PB Core document with 16:9 video' do
      it 'has expected 16:9 attributes' do
        pbc = PBCorePresenter.new(pbc_16_9)
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
        pbc = PBCorePresenter.new(playlist_1)
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
        pbc = PBCorePresenter.new(playlist_2)
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
        pbc = PBCorePresenter.new(playlist_3)
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

    describe 'pbcore object with multiple contributing organizations and states' do
      it 'returns multiple organizations and states' do
        pbc = PBCorePresenter.new(pbc_multi_org)

        expected_attrs = {
          'contributing_organization_names' => ['KQED', 'Library of Congress'],
          'contributing_organizations_facet' => ['KQED (CA)', 'Library of Congress (DC)'],
          'contributing_organization_objects' => [Organization.find_by_pbcore_name('KQED'), Organization.find_by_pbcore_name('Library of Congress')],
          'states' => ['California', 'District of Columbia']
        }

        attrs = {
          'contributing_organization_names' => pbc.contributing_organization_names,
          'contributing_organizations_facet' => pbc.contributing_organizations_facet,
          'contributing_organization_objects' => pbc.contributing_organization_objects,
          'states' => pbc.states
        }

        expect(expected_attrs).to eq(attrs)
      end
    end

    describe '.build_display_title' do
      it 'uses only episode titles if there are more than one series title' do
        expect(PBCorePresenter.new(pbc_multiple_series_with_episodes).title).to eq('Writers Writing; Readers Reading')
      end

      it 'uses only the series and episode titles if there are multiple episode numbers and only one series title' do
        expect(PBCorePresenter.new(pbc_multiple_episodes_one_series).title).to eq('Writers Forum II; Writers Writing Again; Readers Reading Again')
      end

      it 'uses Alternative title if no other titles are present' do
        expect(PBCorePresenter.new(pbc_alternative_title).title).to eq('This Title is Alternative')
      end
    end
  end
end

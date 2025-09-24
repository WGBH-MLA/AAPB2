require 'rails_helper'
require 'resolv'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'
require_relative '../support/feature_test_helper'

describe 'Catalog' do
  IGNORE_FILE = Rails.root.join('spec/support/fixture-ignore.txt')

  let(:onsite_user) do
    instance_double(User,
      onsite?: true,
      aapb_referer?: false,
      embed?: false,
      authorized_referer?: false)
  end

  let(:offsite_user) do
    instance_double(User,
      onsite?: false,
      aapb_referer?: false,
      embed?: false,
      authorized_referer?: false)
  end

  before(:each) do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(onsite_user)

    page.driver.options[:headers] ||= {}
    page.driver.options[:headers]['REMOTE_ADDR'] ||= '198.147.175.1'

    allow_any_instance_of(TranscriptFile).to receive(:file_content).and_return(
      File.read('./spec/fixtures/transcripts/cpb-aacip-111-21ghx7d6-transcript.json')
    )
  end

  # ---------- Helpers ----------
  def expect_count(count, page_text = "")
    case count
    when 0
      expect(page).to have_text('No entries found'), missing_page_text_custom_error('No entries found', page.current_path)
    when 1
      expect(page).to have_text('1 entry found'), missing_page_text_custom_error('1 entry found', page.current_path)
    else
      page_text = page_text.scan(/1 - \d{1,5} of \d{1,5}/).first if page_text.present?
      expect(page).to have_text("1 - #{[count, 10].min} of #{count}"), missing_page_text_custom_error("1 - #{[count, 10].min} of #{count}", page.current_path, page_text)
    end
  end

  def expect_thumbnail(id)
    expect(page).to have_css("img[src='#{AAPB::S3_BASE}/thumbnail/#{id}.jpg']")
  end

  def expect_audio(poster: nil)
    expect(page).not_to have_text('Online Reading Room Rules of Use')
    expect(page).to have_selector('audio')
    expect(page).to have_css("audio[poster='#{poster}']") if poster
  end

  def expect_video(poster: nil)
    expect(page).not_to have_text('Online Reading Room Rules of Use')
    expect(page).to have_selector('video')
    expect(page).to have_css("video[poster='#{poster}']") if poster
  end

  def expect_no_media
    expect(page).not_to have_css('video')
    expect(page).not_to have_css('audio')
  end

  def expect_external_reference
    expect(page).to have_text('More information on this record is available.'), missing_page_text_custom_error('More information on this record is available.', page.current_path)
  end

  def expect_transcript
    expect(page).to have_css('.play-from-here')
  end

  def expect_no_transcript
    expect(page).not_to have_css('.play-from-here')
  end

  def s3_thumb(id)
    "#{AAPB::S3_BASE}/thumbnail/#{id}.jpg"
  end

  # ---------- #index tests ----------
  describe '#index' do
    it 'has facet messages' do
      visit '/catalog'
      expect(page).to have_text('Cataloging in progress: only half of the records for digitized assets are currently dated.'), missing_page_text_custom_error('Cataloging in progress: only half of the records for digitized assets are currently dated.', page.current_path)
    end

    it 'can find one item' do
      visit "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&q=\"cpb-aacip-1234\""
      expect(page.status_code).to eq(200)
      expect_count(1, page.text)
      [
        'Nova; Gratuitous Explosions; 3-2-1; Kaboom!',
        'Date: 2000-01-01',
        'Producing Organization: WGBH',
        'Best episode ever!'
      ].each do |field|
        expect(page).to have_text(field), missing_page_text_custom_error(field, page.current_path)
      end

      expect_thumbnail('cpb-aacip-1234')
    end

    it 'offers to broaden search' do
      visit "/catalog?q=xkcd&f[access_types][]=#{PBCorePresenter::PUBLIC_ACCESS}"
      expect(page).to have_text('No entries found'), missing_page_text_custom_error('No entries found', page.current_path)

      click_link 'searching all records'
      expect(page).to have_text('Consider using other search terms or removing filters.'), missing_page_text_custom_error('Consider using other search terms or removing filters.', page.current_path)
    end

    # ---------- Search constraints ----------
    describe 'search constraints' do
      describe 'title facets' do
        [
          ['f[series_titles][]=Nova', 1],
          ['f[program_titles][]=Gratuitous+Explosions', 1]
        ].each do |param, count|
          it "view /catalog?f[access_types][]=ALL_ACCESS&#{param}" do
            visit "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&#{param}"
            expect(page.status_code).to eq(200)
            expect_count(count, page.text)
          end
        end
      end

      describe 'facets' do
        assertions = [
          ['media_type', 1, 'Sound', 13],
          ['genres', 2, 'Interview', 5],
          ['topics', 1, 'Music', 3],
          ['asset_type', 1, 'Segment', 9],
          ['contributing_organizations', 38, 'WGBH+(MA)', 6],
          ['producing_organizations', 4, 'KQED-TV (Television station : San Francisco, Calif.)', 1]
        ]

        # xit-ing as this appears to be standard Blacklight functionality
        xit 'has them all' do
          visit "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}"
          expect(
            page.all('.panel-heading[data-target]').map do |node|
              node['data-target'].gsub('#facet-', '')
            end
          ).to eq(assertions.map(&:first)) # coverage
        end

        assertions.each do |facet, facet_count, value, value_count|
          url = "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&f[#{facet}][]=#{value}"

          # xit-ing as this appears to be standard Blacklight functionality
          xit "#{facet}=#{value}: #{value_count}\t#{url}" do
            visit url

            # range_limit facet for year does not produce these elements, skip
            expect(
              page.all("#facet-#{facet} li a.facet_select").count
            ).to eq facet_count # expected number of values for each facet
            expect(page.status_code).to eq(200)
            expect_count(value_count, page.text)
          end
        end
      end

      describe 'facets not in sidebar' do
        describe 'states facet' do
          assertions = [
            ['states', 'Michigan', 3]
          ]
          assertions.each do |facet, value, value_count|
            url = "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&f[#{facet}][]=#{value}"
            it "#{facet}=#{value}: #{value_count}\t#{url}" do
              visit url
              expect_count(value_count, page.text)
            end
          end
        end

        describe 'access facet' do
          assertions = [
            ['access_types', PBCorePresenter::ALL_ACCESS, 43]
          ]
          assertions.each do |facet, value, value_count|
            url = "/catalog?f[#{facet}][]=#{value}"

            # xit-ing as this appears to be standard Blacklight functionality
            xit "#{facet}=#{value}: #{value_count}\t#{url}" do
              visit url
              expect_count(value_count, page.text)
            end
          end
        end
      end

      describe 'facet ORs' do
        describe 'URL support' do
          # OR is supported on all facets, even if not in the UI.
          assertions = [
            ['media_type', 'Sound', 13],
            ['media_type', 'Sound+OR+Moving+Image', 38],
            ['media_type', 'Moving+Image+OR+Sound', 38],
            ['media_type', 'Moving+Image', 25]
          ]
          assertions.each do |facet, value, value_count|
            url = "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&f[#{facet}][]=#{value}"

            describe "visiting #{url}" do
              # xit-ing as this appears to be standard Blacklight functionality
              xit "has #{value_count} results" do
                visit url
                expect_count(value_count, page.text)
              end
            end
          end
        end

        it 'works in the UI' do
          visit '/catalog?f[access_types][]=online'

          # commenting out as this appears to be standard Blacklight functionality
          # expect_count(10, page.text)
          # expect(page).to have_text('You searched for: Access online'), missing_page_text_custom_error('You searched for: Access online', page.current_path)

          click_link('All Records')
          # commenting out as this appears to be standard Blacklight functionality
          # expect_count(43, page.text)
          # expect(page).to have_text('You searched for: Access all'), missing_page_text_custom_error('You searched for: Access all', page.current_path)
          expect(page).to have_field('KQED__CA_', checked: false)
          # turn on
          click_link('KQED (CA)')
          expect(page).to have_field('KQED__CA_', checked: true)
          expect_count(3, page.text)
          expect(page).to have_text('You searched for: Access all Remove constraint Access: all '\
                                    'Contributing Organizations KQED (CA) Remove constraint Contributing Organizations: KQED (CA)'), missing_page_text_custom_error('You searched for: Access all Remove constraint Access: all '\
                                    'Contributing Organizations KQED (CA) Remove constraint Contributing Organizations: KQED (CA)', page.current_path)

          # turn on
          click_link('WGBH (MA)')
          expect_count(9, page.text)
          expect(page).to have_text('You searched for: Access all Remove constraint Access: all '\
                                    'Contributing Organizations KQED (CA) OR WGBH (MA) Remove constraint Contributing Organizations: KQED (CA) OR WGBH (MA)'), missing_page_text_custom_error('You searched for: Access all Remove constraint Access: all '\
                                    'Contributing Organizations KQED (CA) OR WGBH (MA) Remove constraint Contributing Organizations: KQED (CA) OR WGBH (MA)', page.current_path)

          # turn off
          click_link('KQED (CA)')
          expect_count(6, page.text)
          expect(page).to have_text('You searched for: Access all Remove constraint Access: all '\
                                    'Contributing Organizations WGBH (MA) Remove constraint Contributing Organizations: WGBH (MA)'), missing_page_text_custom_error('You searched for: Access all Remove constraint Access: all '\
                                    'Contributing Organizations WGBH (MA) Remove constraint Contributing Organizations: WGBH (MA)', page.current_path)

          click_link('All Digitized')

          expect_count(5, page.text)
          expect(page).to have_text('You searched for: Contributing Organizations WGBH (MA) Remove constraint Contributing Organizations: WGBH (MA) '), missing_page_text_custom_error('You searched for: Contributing Organizations WGBH (MA) Remove constraint Contributing Organizations: WGBH (MA) ', page.current_path)

          # click_link('Iowa Public Television (IA)')
          # TODO: check count when IP set in request.
          # expect(page).to have_text('Contributing Organizations: WGBH (MA) OR Iowa Public Television (IA)'), missing_page_text_custom_error('Contributing Organizations: WGBH (MA) OR Iowa Public Television (IA)', page.current_path)
          # expect(page).to have_css('a', text: 'District of Columbia')
          # click_link('District of Columbia')
          # expect(page).to have_text('WGBH (MA) OR Iowa Public Television (IA) OR Library of Congress (DC) OR NewsHour Productions (DC)'), missing_page_text_custom_error('WGBH (MA) OR Iowa Public Television (IA) OR Library of Congress (DC) OR NewsHour Productions (DC)', page.current_path)
          # all(:css, '.constraints-container a.remove')[1].click # remove 'WGBH OR IPTV'
          # TODO: check count when IP set in request.
          # expect(page).to have_text('You searched for: Access online Remove constraint Access: online 1 - 2 of 2')
        end
      end

      describe 'exhibit facet' do
        describe 'in gallery' do
          it 'has exhibit breadcrumb' do
            visit '/catalog?f[exhibits][]=station-histories&view=gallery&f[access_types][]=' + PBCorePresenter::ALL_ACCESS
            expect(page).to have_text('Documenting and Celebrating Public Broadcasting Station Histories'), missing_page_text_custom_error('Documenting and Celebrating Public Broadcasting Station Histories', page.current_path)
          end
        end

        describe 'in list' do
          it 'has exhibit breadcrumb' do
            visit '/catalog?f[exhibits][]=station-histories&view=list&f[access_types][]=' + PBCorePresenter::ALL_ACCESS
            expect(page).to have_text('Documenting and Celebrating Public Broadcasting Station Histories'), missing_page_text_custom_error('Documenting and Celebrating Public Broadcasting Station Histories', page.current_path)
          end
        end
      end

      describe 'special collection facet search' do
        it 'has collection specific search panel' do
          visit '/catalog?f[special_collections][]=ken-burns-civil-war&view=list&f[access_types][]=' + PBCorePresenter::ALL_ACCESS
          expect(page).to have_text('Need Help Searching?'), missing_page_text_custom_error('Need Help Searching?', page.current_path)
        end
      end

      describe 'sorting' do
        describe 'relevance sorting' do
          # all 10 because we're only looking at first page results
          assertions = [
            ['Iowa', ['Touchstone 108', 'Dr. Norman Borlaug; B-Roll', 'Musical Encounter; 116; Music for Fun', 'Bob Brozman', 'Nixon Impeachment Hearings; 2; 1974-07-24; Part 2 of 3', 'The Civil War; Interviews with Barbara Fields', '1974 Nixon Impeachment Hearings; 1974-07-26; Part 3 of 6']],
            ['art', ['The Scheewe Art Workshop', 'Unknown', 'Origami; 7; Paper Ball', 'Japanese Brush Painting; 2; Fish', 'A Sorting Test: 100', 'Racing the Rez', 'Musical Performance of Appalachian Folk Music in Kentucky', 'Nixon Impeachment Hearings; 2; 1974-07-24; Part 2 of 3', 'Nixon Impeachment Hearings; 2; 1974-07-24; Part 1 of 3', '15th Anniversary Show']],
            ['John', ['World Cafe; Larry Kane On John Lennon 2005', 'Dr. Norman Borlaug; B-Roll', 'The Civil War; Interview with Daisy Turner', '1974 Nixon Impeachment Hearings; 1974-07-26; Part 3 of 6', 'Nixon Impeachment Hearings; 2; 1974-07-24; Part 3 of 3', 'The Civil War; Interviews with Barbara Fields', 'Nixon Impeachment Hearings; 2; 1974-07-24; Part 2 of 3', 'Racing the Rez', 'Nixon Impeachment Hearings; 2; 1974-07-24; Part 1 of 3', 'Musical Performance of Appalachian Folk Music in Kentucky']]
          ]
          assertions.each do |query, titles|
            url = "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&q=#{query}"

            # xit-ing out as this appears to be standard Blacklight functionality
            xit "sort=score+desc: #{titles}\t#{url}" do
              visit url
              expect(page.status_code).to eq(200)
              expect(page.all('.document h2').map(&:text)).to eq(titles)
            end
          end
        end

        describe 'field sorting' do
          assertions = [
            ['asset_date+desc', 'Writers Forum II; Writers Writing Again; Readers Reading Again'],
            ['asset_date+asc', 'Winston Churchill Obituary'],
            ['title+asc', 'Ask Governor Chris Gregoire']
          ]
          assertions.each do |sort, title|
            url = "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&sort=#{sort}"

            # xit-ing out as this appears to be standard Blacklight functionality
            xit "sort=#{sort}: '#{title}'\t#{url}" do
              visit url
              expect(
                # NOTE: We do not check relevance sort here, because,
                # without a query, every result has a relevance of "1".
                page.all('#sort-dropdown .dropdown-menu a').map do |node|
                  node['href'].gsub(/.*sort=/, '')
                end - ['score+desc']
              ).to eq(assertions.map(&:first)) # coverage
              expect(page.status_code).to eq(200)
              expect(page.find('.document[1] h2').text).to eq(title)
            end
          end
        end

        describe 'sorting, title edge cases' do
          url = "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&sort=title+asc&per_page=50"

          # xit-ing out as this appears to be standard Blacklight functionality
          xit 'works' do
            visit url
            expect(page.status_code).to eq(200)
            expect(
              page.all('article').map do |art|
                art.all('h2').map do |h|
                  begin
                    h.text.to_s.strip
                  rescue
                    nil # TODO: Why are we getting elements which aren't in the source?
                  end
                end
              end.join("\n")).to eq([
                ['Ask Governor Chris Gregoire'],
                ['Askc: Ask Congress; #508'],
                ['Bob Brozman'],
                ['The Civil War; Interview with Daisy Turner'],
                ['The Civil War; Interviews with Barbara Fields'],
                ['Dance for Camera; Tzaddik; 102'],
                ['Dr. Norman Borlaug; B-Roll'],
                ['Dry Spell'],
                ['Four Decades of Dedication: The 40th Anniversary Special; Handles missing titleTypes, too.'],
                ['From Bessie Smith to Bruce Springsteen'],
                ['Gvsports'],
                ['Japanese Brush Painting; 2; Fish'],
                ['The Lost Year'],
                ['The MacNeil/Lehrer NewsHour'],
                ['Making It Here; 105; Sweets'],
                ['MSOM Field Tape - BUG 12'],
                ['Musical Encounter; 116; Music for Fun'],
                ['Musical Performance of Appalachian Folk Music in Kentucky'],
                ['Nixon Impeachment Hearings; 2; 1974-07-24; Part 1 of 3'],
                ['Nixon Impeachment Hearings; 2; 1974-07-24; Part 2 of 3'],
                ['Nixon Impeachment Hearings; 2; 1974-07-24; Part 3 of 3'],
                ['Nova; Gratuitous Explosions; 3-2-1; Kaboom!'],
                ['Origami; 7; Paper Ball'],
                ['Podcast Release Form'],
                ['Racing the Rez'],
                ['Reading Aloud; MacLeod: The Palace Guard'],
                ['The Scheewe Art Workshop'],
                ['The Sorting Test: 1'],
                ['# "SORTING" Test: 2'],
                ['A Sorting Test: 100'],
                ['This Title is Alternative'],
                ['Touchstone 108'],
                ['Unknown'],
                ['Winston Churchill Obituary'],
                ['World Cafe; Howard Kramer 2004'],
                ['World Cafe; Larry Kane On John Lennon 2005'],
                ['World Cafe; 1997-01-20 Sat/Mon; Martin Luther King, Jr. 1997'],
                ['WQXR; This is My Music; Judd Hirsch'],
                ['Writers Forum II; Writers Writing Again; Readers Reading Again'],
                ['Writers Forum; WRF-09/13/07'],
                ['Writers Writing; Readers Reading'],
                ['15th Anniversary Show'],
                ['1974 Nixon Impeachment Hearings; 1974-07-26; Part 3 of 6']
              ].map { |x| x.join('; ') }.join("\n"))
          end
        end
      end
    end
  end

  # ---------- Quoted phrase OR search ----------
  context 'quoted phrases in "OR" search' do
    let(:quoted_phrases) { '"Film and Television" OR "Event Coverage"' }

    it 'matches when phrase is at the beginning' do
      visit "/catalog?q=#{quoted_phrases}+OR+blergifoo&f[access_types][]=all"
      expect_count(2)
    end

    it 'matches when phrase is at the end' do
      visit "/catalog?q=blergifoo+OR+#{quoted_phrases}&f[access_types][]=all"
      expect_count(2)
    end

    it 'matches when phrase is in the middle' do
      visit "/catalog?q=blergifoo+OR+#{quoted_phrases}+OR+blergifoo&f[access_types][]=all"
      expect_count(2)
    end
  end

  # ---------- .pbcore & .mods ----------
  describe '.pbcore' do
    it 'returns valid XML' do
      visit '/catalog/cpb-aacip-1234.pbcore'
      expect(page.status_code).to eq(200)
      expect { ValidatedPBCore.new(page.source) }.not_to raise_error
      expect(page.response_headers['Content-Type']).to eq('text/xml; charset=utf-8')
    end
  end

  describe '.mods' do
    it 'matches fixture' do
      visit '/catalog/cpb-aacip-1234.mods'
      expect(page.status_code).to eq(200)
      expect(page.source).to eq(File.read(Rails.root.join('spec/fixtures/pbcore/clean-MOCK.mods')))
      expect(page.response_headers['Content-Type']).to eq('text/xml; charset=utf-8')
    end
  end

  # ---------- #show tests ----------
  describe '#show' do
    def expect_all_the_text(fixture_name)
      target = PBCorePresenter.new(File.read("spec/fixtures/pbcore/#{fixture_name}"))
      text_ignores = [target.ids].flatten
      target.send(:text).each do |field|
        field.gsub!('cpb-aacip_', 'cpb-aacip/') if field =~ /^cpb-aacip/
        next if text_ignores.include?(field)
        expect(page).to have_text(field)
      end
    end

    it 'returns 404 for bad id' do
      visit '/catalog/thisaintreal'
      expect(page.status_code).to eq(404)
    end

    it 'displays thumbnails for outside_urls' do
      visit '/catalog/cpb-aacip-1234'
      expect_thumbnail('cpb-aacip-1234')
      expect_no_media
      expect_external_reference
    end

    it 'shows video poster when media present' do
      visit 'catalog/cpb-aacip_37-16c2fsnr'
      expect_all_the_text('clean-every-title-is-episode-number.xml')
      expect_video(poster: s3_thumb('cpb-aacip-37-16c2fsnr'))
    end

    it 'shows default poster for audio' do
      visit 'catalog/cpb-aacip_169-9351chfc'
      expect_all_the_text('clean-audio-digitized.xml')
      expect_audio(poster: '/thumbs/AUDIO.png')
    end
        it 'apologizes if no access' do
      visit '/catalog/cpb-aacip-80-12893j6c'
      # No need to click through
      expect_all_the_text('clean-bad-essence-track.xml')
      expect(page).to have_text('This content is not available.'), missing_page_text_custom_error('This content is not available.', page.current_path)
      expect_no_media
    end

    it 'links to exhibit' do
      visit '/catalog/cpb-aacip_111-21ghx7d6'
      expect(page).to have_text('This record is featured in'), missing_page_text_custom_error('This record is featured in', page.current_path)
      expect_video(poster: s3_thumb('cpb-aacip-111-21ghx7d6'))
    end

    it 'has a transcript if expected' do
      visit '/catalog/cpb-aacip_111-21ghx7d6'
      expect_transcript
    end

    it 'has no transcript if expected' do
      visit '/catalog/cpb-aacip_508-g44hm5390k'
      expect_no_transcript
    end

    describe 'access control' do
      it 'has warning for non-us access' do
        ENV['RAILS_TEST_IP_ADDRESS'] = '0.0.0.0'
        visit 'catalog/cpb-aacip_37-16c2fsnr'
        ENV.delete('RAILS_TEST_IP_ADDRESS')
        expect_all_the_text('clean-every-title-is-episode-number.xml')
        expect(page).to have_text('not available at your location.'), missing_page_text_custom_error('not available at your location.', page.current_path)
        expect_no_media
      end

      it 'has warning for off-site access' do
        ENV['RAILS_TEST_IP_ADDRESS'] = Resolv.getaddress('umass.edu')
        visit 'catalog/cpb-aacip_111-21ghx7d6'
        ENV.delete('RAILS_TEST_IP_ADDRESS')
        expect_all_the_text('clean-exhibit.xml')
        expect(page).to have_text('only available at GBH and the Library of Congress'), missing_page_text_custom_error('only available at GBH and the Library of Congress. ', page.current_path)
        expect_no_media
      end

      it 'requires click-thru for ORR items' do
        ENV['RAILS_TEST_IP_ADDRESS'] = Resolv.getaddress('umass.edu')
        visit 'catalog/cpb-aacip_37-16c2fsnr'
        ENV.delete('RAILS_TEST_IP_ADDRESS')
        expect(page).to have_text('Online Reading Room Rules of Use'), missing_page_text_custom_error('Online Reading Room Rules of Use', page.current_path)
      end

      it 'has both playlist navigation options when applicable' do
        visit 'catalog/cpb-aacip_512-0r9m32nw1x'
        expect(page).to have_css('div#playlist')
        expect(page).to have_text('Part 1'), missing_page_text_custom_error('Part 1', page.current_path)
      end

      it 'has next playlist navigation option when first item in playlist' do
        visit 'catalog/cpb-aacip_512-gx44q7rk20'
        expect(page).to have_css('div#playlist')
        expect(page).not_to have_text('Part 0')
        expect(page).to have_text('Part 2')
      end

      it 'has previous playlist navigation option when last item in playlist' do
        visit 'catalog/cpb-aacip_512-w66930pv96'
        expect(page).to have_css('div#playlist')
        expect(page).to have_text('Part 2'), missing_page_text_custom_error('Part 2', page.current_path)
        expect(page).not_to have_text('Part 4'), found_page_text_custom_error('Part 4', page.current_path)
      end

      it 'should not have #playlist when not in playlist' do
        visit 'catalog/cpb-aacip_111-21ghx7d6'
        expect(page).not_to have_css('div#playlist')
      end
    end
  end

  # ---------- All fixtures tests ----------
  describe 'all fixtures' do
    ignores = Set.new(File.readlines(IGNORE_FILE).map(&:strip))

    Dir['spec/fixtures/pbcore/clean-*.xml'].each do |file_name|
      next if ignores.include?(file_name)

      pbcore = PBCorePresenter.new(File.read(file_name))
      id = pbcore.id

      describe id do
        it "details page for #{id}" do
          visit "/catalog/#{id.gsub('/', '%2F')}"
        end

        xit "search page for #{id}" do
          visit "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&q=#{id.gsub(/^(.*\W)?(\w+)$/, '\2')}"
          expect(page.status_code).to eq(200)
          expect_count(1, page.text)
        end
      end
    end
  end
end

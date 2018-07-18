require 'rails_helper'
require 'resolv'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'
require_relative '../support/validation_helper'

describe 'Catalog' do
  include ValidationHelper

  IGNORE_FILE = Rails.root.join('spec', 'support', 'fixture-ignore.txt')

  before(:all) do
    PBCoreIngester.load_fixtures
  end

  def expect_count(count)
    case count
    when 0
      expect(page).to have_text('No entries found')
    when 1
      expect(page).to have_text('1 entry found')
    else
      expect(page).to have_text("1 - #{[count, 10].min} of #{count}")
    end
  end

  def expect_thumbnail(id)
    url = "#{AAPB::S3_BASE}/thumbnail/#{id}.jpg"
    expect(page).to have_css("img[src='#{url}']")
  end

  # Calls an expectation for a <audio> element
  def expect_audio(opts = {})
    poster = opts[:poster]
    expect(page).not_to have_text('Online Reading Room Rules of Use')
    expect(page).to have_selector('audio')
    expect(page).to have_css("audio[poster='#{poster}']") if poster
  end

  def expect_video(opts = {})
    poster = opts[:poster]
    expect(page).not_to have_text('Online Reading Room Rules of Use')
    expect(page).to have_selector 'video'
    expect(page).to(have_css("video[poster='#{poster}']")) if poster
  end

  def s3_thumb(id)
    "#{AAPB::S3_BASE}/thumbnail/#{id}.jpg"
  end

  def expect_no_media
    expect(page).not_to have_css('video')
    expect(page).not_to have_css('audio')
  end

  def expect_external_reference
    expect(page).to have_text('More information on this record is available.')
  end

  def expect_transcript
    expect(page).to have_css('.play-from-here')
  end

  def expect_no_transcript
    expect(page).not_to have_css('.play-from-here')
  end

  describe '#index' do
    it 'has facet messages' do
      visit '/catalog'
      expect(page).to have_text('Cataloging in progress: only half of the records for digitized assets are currently dated.')
    end

    it 'can find one item' do
      visit "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}&q=1234"
      expect(page.status_code).to eq(200)
      expect_count(1)
      [
        '3-2-1',
        'Kaboom!',
        'Gratuitous Explosions',
        'Series Nova',
        'Date 2000-01-01',
        '2000-01-01',
        'Best episode ever!'
      ].each do |field|
        expect(page).to have_text(field)
      end
      expect_thumbnail(1234)
      expect_fuzzy_xml
    end

    it 'offers to broaden search' do
      visit '/catalog?q=xkcd&f[access_types][]=' + PBCore::PUBLIC_ACCESS
      expect(page).to have_text('No entries found')
      click_link 'searching all records'
      expect(page).to have_text('Consider using other search terms or removing filters.')
    end

    describe 'search constraints' do
      describe 'title facets' do
        assertions = [
          ['f[series_titles][]=Nova', 1],
          ['f[program_titles][]=Gratuitous+Explosions', 1]
        ]
        assertions.each do |(param, count)|
          url = "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}&#{param}"
          it "view #{url}" do
            visit url
            expect(page.status_code).to eq(200)
            expect_count(count)
            expect_fuzzy_xml
          end
        end
      end

      describe 'facets' do
        assertions = [
          ['media_type', 1, 'Sound', 13],
          ['genres', 2, 'Interview', 5],
          ['topics', 1, 'Music', 3],
          ['asset_type', 1, 'Segment', 8],
          ['organizations', 41, 'WGBH+(MA)', 6], # tag ex and states mean lots of facet values.
          ['year', 1, '2000', 1],
          ['access_types', 3, PBCore::ALL_ACCESS, 41]
        ]
        it 'has them all' do
          visit "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}"
          expect(
            page.all('.panel-heading[data-target]').map do |node|
              node['data-target'].gsub('#facet-', '')
            end
          ).to eq(assertions.map(&:first)) # coverage
        end
        assertions.each do |facet, facet_count, value, value_count|
          url = "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}&f[#{facet}][]=#{value}"
          it "#{facet}=#{value}: #{value_count}\t#{url}" do
            visit url
            expect(
              page.all("#facet-#{facet} li a.remove, #facet-#{facet} li a.facet_select").count
            ).to eq facet_count # expected number of values for each facet
            expect(page.status_code).to eq(200)
            expect_count(value_count)
            expect_fuzzy_xml
          end
        end
      end

      describe 'facets not in sidebar' do
        describe 'states facet' do
          assertions = [
            ['states', 'Michigan', 4]
          ]
          assertions.each do |facet, value, value_count|
            url = "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}&f[#{facet}][]=#{value}"
            it "#{facet}=#{value}: #{value_count}\t#{url}" do
              visit url
              expect_count(value_count)
              expect_fuzzy_xml
            end
          end
        end
      end

      describe 'facet ORs' do
        describe 'URL support' do
          # OR is supported on all facets, even if not in the UI.
          assertions = [
            ['media_type', 'Sound', 13],
            ['media_type', 'Sound+OR+Moving+Image', 36],
            ['media_type', 'Moving+Image+OR+Sound', 36],
            ['media_type', 'Moving+Image', 23]
          ]
          assertions.each do |facet, value, value_count|
            url = "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}&f[#{facet}][]=#{value}"

            describe "visiting #{url}" do
              it "has #{value_count} results" do
                visit url
                expect_count(value_count)
              end
            end
          end
        end

        it 'works in the UI' do
          visit '/catalog?f[access_types][]=online'
          expect_count(9)
          expect(page).to have_text('You searched for: Access online')

          click_link('All Records')
          expect_count(41)
          expect(page).to have_text('You searched for: Access all')

          click_link('KQED (CA)')
          expect_count(2)
          expect(page).to have_text('You searched for: Access all Remove constraint Access: all '\
                                    'Organizations KQED (CA) Remove constraint Organizations: KQED (CA)')

          click_link('WGBH (MA)')
          expect_count(8)
          expect(page).to have_text('You searched for: Access all Remove constraint Access: all '\
                                    'Organizations KQED (CA) OR WGBH (MA) Remove constraint Organizations: KQED (CA) OR WGBH (MA)')

          all(:css, 'a.remove').first.click # KQED
          expect_count(6)
          expect(page).to have_text('You searched for: Access all Remove constraint Access: all '\
                                    'Organizations WGBH (MA) Remove constraint Organizations: WGBH (MA)')

          all(:css, '.constraints-container a.remove').first.click # remove access all
          # If you attempt to remove the access facet, it redirects you to the default,
          # but the default depends on requestor's IP address.
          # TODO: set address in request.
          expect_count(4)
          expect(page).to have_text('You searched for: Organizations WGBH (MA) Remove constraint Organizations: WGBH (MA) ')

          click_link('Iowa Public Television (IA)')
          # TODO: check count when IP set in request.
          expect(page).to have_text('Organizations: WGBH (MA) OR Iowa Public Television (IA)')

          # all(:css, '.constraints-container a.remove')[1].click # remove 'WGBH OR IPTV'
          # TODO: check count when IP set in request.
          # expect(page).to have_text('You searched for: Access online Remove constraint Access: online 1 - 2 of 2')
        end
      end

      describe 'exhibit facet' do
        describe 'in gallery' do
          it 'has exhibit breadcrumb' do
            visit '/catalog?f[exhibits][]=station-histories&view=gallery&f[access_types][]=' + PBCore::ALL_ACCESS
            expect(page).to have_text('Documenting and Celebrating Public Broadcasting Station Histories')
          end
        end

        describe 'in list' do
          it 'has exhibit breadcrumb' do
            visit '/catalog?f[exhibits][]=station-histories&view=list&f[access_types][]=' + PBCore::ALL_ACCESS
            expect(page).to have_text('Documenting and Celebrating Public Broadcasting Station Histories')
          end
        end
      end

      describe 'special collection facet search' do
        it 'has collection specific search panel' do
          visit '/catalog?f[special_collection][]=ken-burns-civil-war&view=list&f[access_types][]=' + PBCore::ALL_ACCESS
          expect(page).to have_text('Need Help Searching?')
        end
      end

      describe 'sorting' do
        describe 'relevance sorting' do
          # rubocop:disable LineLength
          assertions = [
            ['Iowa', ['Touchstone 108', 'Dr. Norman Borlaug; B-Roll', 'Musical Encounter; 116; Music for Fun', 'Bob Brozman', 'The Civil War; Interviews with Barbara Fields']],
            ['art', ['The Scheewe Art Workshop', 'Unknown', 'Origami; 7; Paper Ball', 'A Sorting Test: 100', 'Musical Performance of Appalachian Folk Music in Kentucky', '15th Anniversary Show']],
            ['John', ['World Cafe; Larry Kane On John Lennon 2005', 'Dr. Norman Borlaug; B-Roll', 'The Civil War; Interview with Daisy Turner', 'The Civil War; Interviews with Barbara Fields', 'Musical Performance of Appalachian Folk Music in Kentucky', '15th Anniversary Show']]
          ]
          # rubocop:enable LineLength
          assertions.each do |query, titles|
            url = "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}&q=#{query}"
            it "sort=score+desc: #{titles}\t#{url}" do
              visit url
              expect(page.status_code).to eq(200)
              expect(page.all('.document h2').map(&:text)).to eq(titles)
              expect_fuzzy_xml
            end
          end
        end

        describe 'field sorting' do
          assertions = [
            ['year+desc', 'Writers Forum; WRF-09/13/07'],
            ['year+asc', 'Winston Churchill Obituary'],
            ['title+asc', 'Ask Governor Chris Gregoire']
          ]
          assertions.each do |sort, title|
            url = "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}&sort=#{sort}"
            it "sort=#{sort}: '#{title}'\t#{url}" do
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
              expect_fuzzy_xml
            end
          end
        end

        describe 'sorting, title edge cases' do
          url = "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}&sort=title+asc&per_page=50"
          it 'works' do
            # rubocop:disable LineLength
            visit url
            expect(page.status_code).to eq(200)
            expect(
              page.all('#documents/div').map do |doc|
                doc.all('dl').map do |dl|
                  begin
                    "#{dl.find('dt').text}: #{dl.find('dd').text[0..20].strip}"
                  rescue
                    nil # TODO: Why are we getting elements which aren't in the source?
                  end
                end.select { |x| x }.join('; ')
              end.join("\n")).to eq([
                ['Program: Ask Governor Chris Gr', 'Organization: KUOW Puget Sound Publ', 'Media Type: Sound', 'Access: '],
                ['Series: Askc: Ask Congress', 'Episode: #508', 'Organization: WHUT', 'Media Type: other', 'Access: '],
                ['Program: Bob Brozman; Organization: Iowa Public Radio', 'Media Type: Sound', 'Access: Accessible on locatio'],
                ['Series: The Civil War; Raw Footage: Interview with Daisy', 'Created: 1987-05-21', 'Organization: Ken Burns - Florentin', 'Media Type: Moving Image', 'Access: Online Reading Room'],
                ['Series: The Civil War; Raw Footage: Interviews with Barba', 'Created: 1987-01-14', 'Organization: Ken Burns - Florentin', 'Media Type: Moving Image', 'Access: Online Reading Room'],
                ['Series: Dance for Camera; Program: Tzaddik; Episode Number: 102; Organization: WGBH; Media Type: Moving Image; Access: Accessible on locatio'],
                ['Raw Footage: Dr. Norman Borlaug', 'Raw Footage: B-Roll', 'Organization: Iowa Public Televisio', 'Media Type: Moving Image', 'Access: '],
                ['Title: Dry Spell', 'Organization: KQED', 'Media Type: Moving Image', 'Access: '],
                ['Program: Four Decades of Dedic', 'Title: Handles missing title', 'Organization: WPBS', 'Media Type: Moving Image', 'Access: '],
                ['Title: From Bessie Smith to', 'Created: 1990-07-27', 'Date: 1991-07-27', 'Organization: Film and Media Archiv', 'Media Type: Moving Image', 'Access: '],
                ['Series: Gvsports', 'Organization: WGVU Public TV and Ra', 'Media Type: other', 'Access: '],
                ['Series: The Lost Year', 'Organization: Arkansas Educational', 'Media Type: Moving Image', 'Access: Accessible on locatio'],
                ['Series: The MacNeil/Lehrer Ne', 'Date: 1983-10-13', 'Organization: NewsHour Productions', 'Media Type: Moving Image', 'Access: Online Reading Room'],
                ['Series: Making It Here; Episode Number: 105; Episode: Sweets', 'Date: 2003-01-22', 'Organization: WGBY', 'Media Type: Moving Image', 'Access: Online Reading Room'],
                ['Raw Footage: MSOM Field Tape - BUG', 'Organization: Maryland Public Telev', 'Media Type: Moving Image', 'Access: '],
                ['Episode Number: Musical Encounter', 'Episode Number: 116', 'Episode Number: Music for Fun', 'Created: 1988-05-12', 'Organization: Iowa Public Televisio', 'Media Type: Moving Image',
                 'Access: Online Reading Room'],
                ['Raw Footage: Musical Performance o', 'Created: 1992-06-05', 'Organization: Appalshop, Inc.', 'Media Type: Sound', 'Access: Accessible on locatio'],
                ['Series: Nixon Impeachment Hea', 'Episode Number: 2', 'Episode: 1974-07-24', 'Segment: Part 1 of 3', 'Broadcast: 1974-07-24', 'Organization: WGBH', 'Media Type: Moving Image', 'Access: Online Reading Room'],
                ['Series: Nixon Impeachment Hea', 'Episode Number: 2', 'Episode: 1974-07-24', 'Segment: Part 2 of 3', 'Broadcast: 1974-07-24', 'Organization: WGBH', 'Media Type: Moving Image', 'Access: Online Reading Room'],
                ['Series: Nixon Impeachment Hea', 'Episode Number: 2', 'Episode: 1974-07-24', 'Segment: Part 3 of 3', 'Broadcast: 1974-07-24', 'Organization: WGBH', 'Media Type: Moving Image', 'Access: Online Reading Room'],
                ['Series: Nova', 'Program: Gratuitous Explosions', 'Episode Number: 3-2-1', 'Episode: Kaboom!', 'Date: 2000-01-01', 'Organization: WGBH', 'Media Type: Moving Image', 'Access: Online Reading Room'],
                ['Series: Origami; Episode Number: 7', 'Episode: Paper Ball', 'Broadcast: 1961-00-00', 'Media Type: other', 'Access: '],
                ['Title: Podcast Release Form', 'Organization: KXCI Community Radio', 'Media Type: other', 'Access: '],
                ['Title: Racing the Rez', 'Organization: Vision Maker Media', 'Media Type: Moving Image', 'Access: Accessible on locatio'],
                ['Series: Reading Aloud', 'Program: MacLeod: The Palace G', 'Organization: WGBH', 'Media Type: Sound', 'Access: '],
                ['Title: The Scheewe Art Works', 'Organization: Detroit Public Televi', 'Media Type: Moving Image', 'Access: '],
                ['Program: The Sorting Test: 1', 'Organization: WUSF', 'Media Type: other', 'Access: '],
                ['Program: # "SORTING" Test: 2', 'Organization: Detroit Public Televi', 'Media Type: Moving Image', 'Access: '],
                ['Program: A Sorting Test: 100', 'Organization: WNYC', 'Media Type: Moving Image', 'Access: '],
                ['Title: This Title is Alterna', 'Copyright Date: 2006-10-23', 'Organization: WERU Community Radio', 'Media Type: Sound', 'Access: '],
                ['Episode: Touchstone 108', 'Organization: Iowa Public Televisio', 'Media Type: Moving Image', 'Access: '],
                ['Program: Unknown', 'Organization: WIAA', 'Media Type: Sound', 'Access: '],
                ['Program: Winston Churchill Obi', 'Broadcast: 1958-00-00', 'Organization: Library of Congress,', 'Media Type: Moving Image', 'Access: '],
                ['Program: World Cafe', 'Segment: Howard Kramer 2004', 'Organization: WXPN', 'Media Type: Sound', 'Access: '],
                ['Program: World Cafe', 'Segment: Larry Kane On John Le', 'Organization: WXPN', 'Media Type: Sound', 'Access: '],
                ['Program: World Cafe', 'Segment: 1997-01-20 Sat/Mon', 'Segment: Martin Luther King, J', 'Organization: WXPN', 'Media Type: Sound', 'Access: '],
                ['Collection: WQXR', 'Series: This is My Music', 'Episode: Judd Hirsch', 'Organization: WNYC', 'Media Type: Sound', 'Access: '],
                ['Series: Writers Forum II', 'Episode Number: 43', 'Episode Number: 25', 'Episode: Writers Writing Again', 'Episode: Readers Reading Again', 'Copyright Date: 2007-10-15', 'Organization: WERU Community Radio', 'Media Type: Sound', 'Access: '],
                ['Series: Writers Forum', 'Program: WRF-09/13/07', 'Copyright Date: 2007-09-13', 'Organization: WERU Community Radio', 'Media Type: Sound', 'Access: '],
                ['Series: Writers Forum II', 'Series: Readers Forum', 'Episode Number: 42', 'Episode Number: 24', 'Episode: Writers Writing', 'Episode: Readers Reading', 'Copyright Date: 2007-10-13', 'Organization: WERU Community Radio', 'Media Type: Sound', 'Access: '],
                ['Program: 15th Anniversary Show', 'Created: 1981-12-05', 'Organization: Arkansas Educational', 'Media Type: Moving Image', 'Access: Accessible on locatio']
              ].map { |x| x.join('; ') }.join("\n"))
            expect_fuzzy_xml
            # rubocop:enable LineLength
          end
        end
      end
    end
  end

  describe '.pbcore' do
    it 'works' do
      visit '/catalog/1234.pbcore'
      expect(page.status_code).to eq(200)
      expect(page.source).to eq(File.read(Rails.root + 'spec/fixtures/pbcore/clean-MOCK.xml'))
      expect(page.response_headers['Content-Type']).to eq('text/xml; charset=utf-8')
    end
  end

  describe '.mods' do
    it 'works' do
      visit '/catalog/1234.mods'
      expect(page.status_code).to eq(200)
      expect(page.source).to eq(File.read(Rails.root + 'spec/fixtures/pbcore/clean-MOCK.mods'))
      expect(page.response_headers['Content-Type']).to eq('text/xml; charset=utf-8')
    end
  end

  describe '#show' do
    before do
      page.driver.options[:headers] = { 'REMOTE_ADDR' => '198.147.175.1' }
    end

    def expect_all_the_text(fixture_name)
      target = PBCore.new(File.read('spec/fixtures/pbcore/' + fixture_name))

      # This text from the PBCore model is included in to_solr for
      # search purposes, but excluded from view.
      text_ignores = [target.ids].flatten

      # #text is only used for #to_solr, so it's private...
      # so we need the #send to get at it.
      target.send(:text).each do |field|
        field.gsub!('cpb-aacip_', 'cpb-aacip/') if field =~ /^cpb-aacip/ # TODO: Remove when we sort out ID handling.
        next if text_ignores.include?(field)
        expect(page).to have_text(field)
      end
    end

    it 'has thumbnails if outside_url' do
      visit '/catalog/1234'
      expect_all_the_text('clean-MOCK.xml')
      expect_thumbnail('1234') # has media, but also has outside_url, which overrides.
      expect_no_media
      expect_external_reference
    end

    it 'has poster otherwise if media' do
      visit 'catalog/cpb-aacip_37-16c2fsnr'
      expect_all_the_text('clean-every-title-is-episode-number.xml')
      expect_video(poster: s3_thumb('cpb-aacip_37-16c2fsnr'))
    end

    it 'has default poster for audio that ' do
      visit 'catalog/cpb-aacip_169-9351chfc'
      expect_all_the_text('clean-audio-digitized.xml')
      expect_audio(poster: '/thumbs/audio-digitized.jpg')
    end

    it 'apologizes if no access' do
      visit '/catalog/cpb-aacip-80-12893j6c'
      # No need to click through
      expect_all_the_text('clean-bad-essence-track.xml')
      expect(page).to have_text('This content has not been digitized.')
      expect_no_media
    end

    it 'links to collection' do
      visit '/catalog/cpb-aacip_111-21ghx7d6'
      expect(page).to have_text('This record is featured in')
      expect_video(poster: s3_thumb('cpb-aacip_111-21ghx7d6'))
    end

    it 'has a transcript if expected' do
      visit '/catalog/cpb-aacip_111-21ghx7d6'
      expect_transcript
    end

    it 'has a transcript if expected' do
      visit '/catalog/ccpb-aacip_508-g44hm5390k'
      expect_no_transcript
    end

    describe 'access control' do
      it 'has warning for non-us access' do
        ENV['RAILS_TEST_IP_ADDRESS'] = '0.0.0.0'
        visit 'catalog/cpb-aacip_37-16c2fsnr'
        ENV.delete('RAILS_TEST_IP_ADDRESS')
        expect_all_the_text('clean-every-title-is-episode-number.xml')
        expect(page).to have_text('not available at your location.')
        expect_no_media
      end

      it 'has warning for off-site access' do
        ENV['RAILS_TEST_IP_ADDRESS'] = Resolv.getaddress('umass.edu')
        visit 'catalog/cpb-aacip_111-21ghx7d6'
        ENV.delete('RAILS_TEST_IP_ADDRESS')
        expect_all_the_text('clean-exhibit.xml')
        expect(page).to have_text('only available at WGBH and the Library of Congress. ')
        expect_no_media
      end

      it 'requires click-thru for ORR items' do
        ENV['RAILS_TEST_IP_ADDRESS'] = Resolv.getaddress('umass.edu')
        visit 'catalog/cpb-aacip_37-16c2fsnr'
        ENV.delete('RAILS_TEST_IP_ADDRESS')
        expect(page).to have_text('Online Reading Room Rules of Use')
      end

      it 'has both playlist navigation options when applicable' do
        visit 'catalog/cpb-aacip_512-0r9m32nw1x'
        expect(page).to have_css('div#playlist')
        expect(page).to have_text('Part 1')
        expect(page).to have_text('Part 1')
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
        expect(page).to have_text('Part 2')
        expect(page).not_to have_text('Part 4')
      end

      it 'should not have #playlist when not in playlist' do
        visit 'catalog/cpb-aacip_111-21ghx7d6'
        expect(page).not_to have_css('div#playlist')
      end
    end
  end

  describe 'all fixtures' do
    Dir['spec/fixtures/pbcore/clean-*.xml'].each do |file_name|
      # Used to skip XML validation for false errors.
      # Should consider better HTML validation in ValidationHelper.
      ignores = Set.new(File.readlines(IGNORE_FILE).map(&:strip))
      next if ignores.include?(file_name)

      pbcore = PBCore.new(File.read(file_name))
      id = pbcore.id
      describe id do
        details_url = "/catalog/#{id.gsub('/', '%2F')}" # Remember the URLs are tricky.
        it "details: #{details_url}" do
          visit details_url
          expect_fuzzy_xml
        end
        search_url = "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}&&q=#{id.gsub(/^(.*\W)?(\w+)$/, '\2')}"
        # because of tokenization, unless we strip the ID down we will get other matches.
        it "search: #{search_url}" do
          visit search_url
          expect(page.status_code).to eq(200)
          expect_count(1)
          expect_fuzzy_xml
        end
      end
    end
  end
end

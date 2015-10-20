require 'rails_helper'
require 'resolv'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'
require_relative '../support/validation_helper'

describe 'Catalog' do
  include ValidationHelper

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

  def expect_poster(id)
    url = "#{AAPB::S3_BASE}/thumbnail/#{id}.jpg"
    expect(page).to have_css("video[poster='#{url}']")
  end
  
  def expect_no_media()
    expect(page).not_to have_css("video")
    expect(page).not_to have_css("audio")
  end

  describe '#index' do
    it 'has facet messages' do
      visit '/catalog'
      expect(page).to have_text('Cataloging in progress: Only 1/3 of AAPB records are currently dated.')
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
      visit '/catalog?q=nothing-matches-this&f[access_types][]=' + PBCore::PUBLIC_ACCESS
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

      describe 'views' do
        assertions = [
          # Better if we actually looked for something in the results?
          ['&q=smith', '.view-type-list.active'],
          ['&q=smith&view=list', '.view-type-list.active'],
          ['&q=smith&view=gallery', '.view-type-gallery.active']
        ]
        assertions.each do |(params, css)|
          url = "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}&#{params}"
          it "view params=#{params}: #{css}\t#{url}" do
            visit url
            expect(page.status_code).to eq(200)
            expect(page.all(css).count).to eq(1)
            expect_fuzzy_xml
          end
        end
      end

      describe 'facets' do
        assertions = [
          ['media_type', 1, 'Sound', 8],
          ['genres', 2, 'Interview', 3],
          ['topics', 1, 'Music', 1],
          ['asset_type', 1, 'Segment', 5],
          ['organization', 31, 'WGBH+(MA)', 2], # tag ex and states mean lots of facet values.
          ['year', 1, '2000', 1],
          ['access_types', 3, PBCore::ALL_ACCESS, 24]
        ]
        it 'has them all' do
          visit "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}"
          expect(
            page.all('.panel-heading[data-target]').map do |node|
              node['data-target'].gsub('#facet-', '')
            end
          ).to eq(assertions.map { |a| a.first }) # coverage
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
        describe 'state facet' do
          assertions = [
            ['state', 'Michigan', 4]
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
            ['media_type', 'Sound', 8],
            ['media_type', 'Sound+OR+Moving+Image', 20],
            ['media_type', 'Moving+Image+OR+Sound', 20],
            ['media_type', 'Moving+Image', 12]
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
          expect_count(2)
          expect(page).to have_text('You searched for: Access online')
          
          click_link('All Records')
          expect_count(24)
          expect(page).to have_text('You searched for: Access all')
          
          click_link('KQED (CA)')
          expect_count(1)
          expect(page).to have_text('You searched for: Access all Remove constraint Access: all '+
                                    'Organization KQED (CA) Remove constraint Organization: KQED (CA)')
        
          click_link('WGBH (MA)')
          expect_count(3)
          expect(page).to have_text('You searched for: Access all Remove constraint Access: all '+
                                    'Organization KQED (CA) OR WGBH (MA) Remove constraint Organization: KQED (CA) OR WGBH (MA)')
        
          all(:css, 'a.remove').first.click # KQED
          expect_count(2)
          expect(page).to have_text('You searched for: Access all Remove constraint Access: all '+
                                    'Organization WGBH (MA) Remove constraint Organization: WGBH (MA)')
        
          all(:css, '.constraints-container a.remove').first.click # remove access all
          # If you attempt to remove the access facet, it redirects you to the default,
          # but the default depends on requestor's IP address.
          # TODO: set address in request.
          expect_count(1)
          expect(page).to have_text('You searched for: Organization WGBH (MA) Remove constraint Organization: WGBH (MA) ')
                                
          click_link('Iowa Public Television (IA)')
          # TODO: check count when IP set in request.
          expect(page).to have_text('Organization: WGBH (MA) OR Iowa Public Television (IA)')
          
          # all(:css, '.constraints-container a.remove')[1].click # remove 'WGBH OR IPTV'
          # TODO: check count when IP set in request.
          # expect(page).to have_text('You searched for: Access online Remove constraint Access: online 1 - 2 of 2')
        end
      end

      describe 'exhibit facet' do
        describe 'in gallery' do
          it 'has exhibition description' do
            visit '/catalog?f[exhibits][]=station-histories&view=gallery&f[access_types][]=' + PBCore::ALL_ACCESS
            expect(page).to have_text('Every public broadcasting station')
          end

          it 'has individual descriptions' do
            visit '/catalog?f[exhibits][]=station-histories&view=gallery&f[access_types][]=' + PBCore::ALL_ACCESS
            expect(page).to have_text('Dedication ceremony of Arkansas’ new Educational Broadcasting Facility')
          end
        end

        describe 'in list' do
          it 'has exhibit description' do
            visit '/catalog?f[exhibits][]=station-histories&view=list&f[access_types][]=' + PBCore::ALL_ACCESS
            expect(page).to have_text('Every public broadcasting station')
          end

          it 'has individual descriptions' do
            visit '/catalog?f[exhibits][]=station-histories&view=list&f[access_types][]=' + PBCore::ALL_ACCESS
            expect(page).to have_text('dedication ceremony of the new Educational Television facility')
          end
        end
      end

      describe 'sorting' do
        describe 'relevance sorting' do
          assertions = [
            ['Iowa', ['Touchstone 108', 'Musical Encounter; 116; Music for Fun', 'Dr. Norman Borlaug; B-Roll']],
            ['art', ['Scheewe Art Workshop', 'Unknown', 'A Sorting Test: 100']],
            ['John', ['World Cafe; Larry Kane On John Lennon 2005', 'Dr. Norman Borlaug; B-Roll']]
          ]
          assertions.each do |query, titles|
            url = "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}&q=#{query}"
            it "sort=score+desc: #{titles}\t#{url}" do
              visit url
              expect(page.status_code).to eq(200)
              expect(page.all('.document h2').map { |node| node.text }).to eq(titles)
              expect_fuzzy_xml
            end
          end
        end

        describe 'field sorting' do
          assertions = [
            ['year+desc', 'Nova; Gratuitous Explosions; 3-2-1; Kaboom!'],
            ['year+asc', '15th Anniversary Show'],
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
              ).to eq(assertions.map { |a| a.first }) # coverage
              expect(page.status_code).to eq(200)
              expect(page.find('.document[1] h2').text).to eq(title)
              expect_fuzzy_xml
            end
          end
        end

        describe 'sorting, title edge cases' do
          url = "/catalog?f[access_types][]=#{PBCore::ALL_ACCESS}&sort=title+asc&per_page=50"
          it 'works' do
            visit url
            expect(page.status_code).to eq(200)
            expect(
              page.all('#documents/div').map do |doc|
                doc.all('dl').map do |dl|
                  "#{dl.find('dt').text}: #{dl.find('dd').text[0..20].strip}"
                end.join('; ')
              end.join("\n")).to eq([
                ['Program: Ask Governor Chris Gr', 'Organization: KUOW Puget Sound Publ'],
                ['Series: Askc: Ask Congress', 'Episode: #508', 'Organization: WHUT'],
                ['Raw Footage: Dr. Norman Borlaug', 'Raw Footage: B-Roll', 'Organization: Iowa Public Televisio'],
                ['Title: Dry Spell', 'Organization: KQED'],
                ['Program: Four Decades of Dedic', 'Title: Handles missing title', 'Organization: WPBS'],
                ['Title: From Bessie Smith to', 'Created: 1990-07-27', 'Date: 1991-07-27', 'Organization: Film and Media Archiv'],
                ['Series: Gvsports', 'Organization: WGVU Public TV and Ra'],
                ['Raw Footage: MSOM Field Tape - BUG', 'Organization: Maryland Public Telev'],
                ['Episode Number: Musical Encounter', 'Episode Number: 116', 'Episode Number: Music for Fun', 'Created: 1988-05-12', 'Organization: Iowa Public Televisio'],
                ['Series: Nova', 'Program: Gratuitous Explosions', 'Episode Number: 3-2-1', 'Episode: Kaboom!', 'Date: 2000-01-01', 'Organization: WGBH'],
                ['Title: Podcast Release Form', 'Organization: KXCI Community Radio'],
                ['Series: Reading Aloud', 'Program: MacLeod: The Palace G', 'Organization: WGBH'],
                ['Title: Scheewe Art Workshop', 'Organization: Detroit Public Televi'],
                ['Program: The Sorting Test: 1', 'Organization: WUSF'],
                ['Program: SORTING Test: 2', 'Organization: Detroit Public Televi'],
                ['Program: A Sorting Test: 100', 'Organization: WNYC'],
                ['Episode: Touchstone 108', 'Organization: Iowa Public Televisio'],
                ['Program: Unknown', 'Organization: WIAA'],
                ['Program: World Cafe', 'Segment: Howard Kramer 2004', 'Organization: WXPN'],
                ['Program: World Cafe', 'Segment: Larry Kane On John Le', 'Organization: WXPN'],
                ['Program: World Cafe', 'Segment: 1997-01-20 Sat/Mon', 'Segment: Martin Luther King, J', 'Organization: WXPN'],
                ['Collection: WQXR', 'Series: This is My Music', 'Episode: Judd Hirsch', 'Organization: WNYC'],
                ['Series: Writers Forum', 'Program: WRF-09/13/07', 'Organization: WERU Community Radio'],
                ['Program: 15th Anniversary Show', 'Created: 1981-12-05', 'Organization: Arkansas Educational']
              ].map { |x| x.join('; ') }.join("\n"))
            expect_fuzzy_xml
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

  describe '#show' do
    AGREE = 'I agree'

    def expect_all_the_text(fixture_name)
      target = PBCore.new(File.read('spec/fixtures/pbcore/'+fixture_name))
      # #text is only used for #to_solr, so it's private...
      # so we need the #send to get at it.
      target.send(:text).map { |s| s.gsub('_', '/') }.each do |field|
        # The ID is on the page, but it has a slash, not underscore.
        expect(page).to have_text(field)
      end
    end
    
    it 'has thumbnails if outside_url' do
      visit '/catalog/1234'
      expect_all_the_text('clean-MOCK.xml')
      expect_thumbnail('1234') # has media, but also has outside_url, which overrides.
      expect_no_media()
    end

    it 'has poster otherwise if media' do
      visit 'catalog/cpb-aacip_37-16c2fsnr'
      expect_all_the_text('clean-every-title-is-episode-number.xml')
      expect_poster('cpb-aacip_37-16c2fsnr')
    end
    
    it 'apologizes if no access' do
      visit '/catalog/cpb-aacip_80-12893j6c'
      # No need to click through
      expect_all_the_text('clean-bad-essence-track.xml')
      expect(page).to have_text('This content has not been digitized.')
      expect_no_media()
    end
    
    it 'links to collection' do
      visit '/catalog/cpb-aacip_111-21ghx7d6'
      expect(page).to have_text('This record is featured in')
      expect_poster('cpb-aacip_111-21ghx7d6')
    end
    
    describe 'access control' do
      it 'has warning for non-us access' do
        ENV['RAILS_TEST_IP_ADDRESS'] = '0.0.0.0'
        visit 'catalog/cpb-aacip_37-16c2fsnr'
        ENV.delete('RAILS_TEST_IP_ADDRESS')
        expect_all_the_text('clean-every-title-is-episode-number.xml')
        expect(page).to have_text('not available for viewing at your location.')
        expect_no_media()
      end
      
      it 'has warning for off-site access' do
        ENV['RAILS_TEST_IP_ADDRESS'] = Resolv.getaddress('umass.edu')
        visit 'catalog/cpb-aacip_111-21ghx7d6'
        ENV.delete('RAILS_TEST_IP_ADDRESS')
        expect_all_the_text('clean-exhibit.xml')
        expect(page).to have_text('only available for viewing at WGBH and the Library of Congress. ')
        expect_no_media()
      end
    end
  end

  describe 'all fixtures' do
    Dir['spec/fixtures/pbcore/clean-*.xml'].each do |file_name|
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

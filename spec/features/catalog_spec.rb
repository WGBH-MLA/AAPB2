require 'rails_helper'
require 'resolv'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'
require_relative '../../scripts/lib/cleaner'
require_relative '../support/validation_helper'
require_relative '../support/feature_test_helper'


describe 'Catalog' do
  include ValidationHelper

  IGNORE_FILE = Rails.root.join('spec', 'support', 'fixture-ignore.txt')

  def expect_count(count)
    case count
    when 0
      expect(page).to have_text('No entries found'), missing_page_text_custom_error('No entries found', page.current_path)
    when 1
      expect(page).to have_text('1 entry found'), missing_page_text_custom_error('1 entry found', page.current_path)
    else
      expect(page).to have_text("1 - #{[count, 10].min} of #{count}"), missing_page_text_custom_error("1 - #{[count, 10].min} of #{count}", page.current_path)
    end
  end

  def expect_thumbnail(id)
    url = "#{AAPB::S3_BASE}/thumbnail/#{id}.jpg"
    expect(page).to have_css("img[src='#{url}']")
  end

  # Calls an expectation for a <audio> element
  def expect_audio(opts = {})
    poster = opts[:poster]
    expect(page).not_to have_text('Online Reading Room Rules of Use'), found_page_text_custom_error('Online Reading Room Rules of Use', page.current_path)
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
    expect(page).to have_text('More information on this record is available.'), missing_page_text_custom_error('More information on this record is available.', page.current_path)
  end

  def expect_transcript
    expect(page).to have_css('.play-from-here')
  end

  def expect_no_transcript
    expect(page).not_to have_css('.play-from-here')
  end

  describe '#index' do

    before(:all) do
      PBCoreIngester.new.delete_all
      cleaner = Cleaner.instance

      @full_xml = just_xml(build(:pbcore_description_document, :full_aapb, :wgbh_org))
      @private_xml = just_xml(build(:pbcore_description_document, :full_aapb, :access_level_protected))
      @public_xml = just_xml(build(:pbcore_description_document, :full_aapb, :access_level_public, :kqed_org))
      @ingested_records = []
      [@full_xml, @private_xml, @public_xml].each do |xml|
        PBCoreIngester.ingest_record_from_xmlstring(xml)
      end

      @full_record = PBCorePresenter.new(cleaner.clean(@full_xml))
      @private_record = PBCorePresenter.new(cleaner.clean(@private_xml))
      @public_record = PBCorePresenter.new(cleaner.clean(@public_xml))
    end

    # dont need records
    it 'has facet messages' do
      visit '/catalog'
      expect(page).to have_text('Cataloging in progress: only half of the records for digitized assets are currently dated.'), missing_page_text_custom_error('Cataloging in progress: only half of the records for digitized assets are currently dated.', page.current_path)
    end

    
    # do need records
    it 'can find one item' do
      visit "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&q=id:#{@ingested_records.first.id}"
      expect(page.status_code).to eq(200)
      expect_count(1)
      expect(page).to have_text(@ingested_records.first.title), missing_page_text_custom_error(@ingested_records.first.title, page.current_path)
        expect_thumbnail(@ingested_records.first.id)
    end

    it 'offers to broaden search' do
      visit '/catalog?q=xkcd&f[access_types][]=' + PBCorePresenter::PUBLIC_ACCESS
      expect(page).to have_text('No entries found'), missing_page_text_custom_error('No entries found', page.current_path)
      click_link 'searching all records'
      expect(page).to have_text('Consider using other search terms or removing filters.'), missing_page_text_custom_error('Consider using other search terms or removing filters.', page.current_path)
    end

    it 'can facet by series title' do
      visit "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&f[series_titles][]=#{ @full_record.titles['series'] }"
      expect(page).to have_text(@full_record.title)
    end

    it 'can facet by program title' do
      visit "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&f[program_titles][]=#{ @full_record.titles['Program'] }"
      expect(page).to have_text(@full_record.title)
    end

    it 'can facet by program title' do
      visit "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&f[states][]=#{@full_record.states.first}"
      expect(page).to have_text(@full_record.title)
    end

    it 'works in the UI' do
          visit '/catalog?f[access_types][]=online'

          click_link('All Records')

          expect(page).to have_field('KQED__CA__KQED__CA_', checked: false)
          click_link('KQED (CA)')
          expect(page).to have_field('KQED__CA__KQED__CA_', checked: true)
          expect_count(1)
          expect(page).to have_text('You searched for: Access all Remove constraint Access: all '\
                                    'Contributing Organizations KQED (CA) Remove constraint Contributing Organizations: KQED (CA)'), missing_page_text_custom_error('You searched for: Access all Remove constraint Access: all '\
                                    'Contributing Organizations KQED (CA) Remove constraint Contributing Organizations: KQED (CA)', page.current_path)

          click_link('WGBH (MA)')
          expect_count(9)
          expect(page).to have_text('You searched for: Access all Remove constraint Access: all '\
                                    'Contributing Organizations KQED (CA) OR WGBH (MA) Remove constraint Contributing Organizations: KQED (CA) OR WGBH (MA)'), missing_page_text_custom_error('You searched for: Access all Remove constraint Access: all '\
                                    'Contributing Organizations KQED (CA) OR WGBH (MA) Remove constraint Contributing Organizations: KQED (CA) OR WGBH (MA)', page.current_path)

          click_link('KQED (CA)')
          expect_count(6)
          expect(page).to have_text('You searched for: Access all Remove constraint Access: all '\
                                    'Contributing Organizations WGBH (MA) Remove constraint Contributing Organizations: WGBH (MA)'), missing_page_text_custom_error('You searched for: Access all Remove constraint Access: all '\
                                    'Contributing Organizations WGBH (MA) Remove constraint Contributing Organizations: WGBH (MA)', page.current_path)

          all(:css, '.constraints-container a.remove').first.click # remove access all
          # If you attempt to remove the access facet, it redirects you to the default,
          # but the default depends on requestor's IP address.
          # TODO: set address in request.
          expect_count(4)
          expect(page).to have_text('You searched for: Contributing Organizations WGBH (MA) Remove constraint Contributing Organizations: WGBH (MA) '), missing_page_text_custom_error('You searched for: Contributing Organizations WGBH (MA) Remove constraint Contributing Organizations: WGBH (MA) ', page.current_path)

          click_link('Iowa Public Television (IA)')
          # TODO: check count when IP set in request.
          expect(page).to have_text('Contributing Organizations: WGBH (MA) OR Iowa Public Television (IA)'), missing_page_text_custom_error('Contributing Organizations: WGBH (MA) OR Iowa Public Television (IA)', page.current_path)

          expect(page).to have_css('a', text: 'District of Columbia')
          click_link('District of Columbia')
          expect(page).to have_text('WGBH (MA) OR Iowa Public Television (IA) OR Library of Congress (DC) OR NewsHour Productions (DC)'), missing_page_text_custom_error('WGBH (MA) OR Iowa Public Television (IA) OR Library of Congress (DC) OR NewsHour Productions (DC)', page.current_path)

          # all(:css, '.constraints-container a.remove')[1].click # remove 'WGBH OR IPTV'
          # TODO: check count when IP set in request.
          # expect(page).to have_text('You searched for: Access online Remove constraint Access: online 1 - 2 of 2')
    end

      # describe 'facets' do
      #   assertions = [
      #     ['media_type', 1, 'Sound', 13],
      #     ['genres', 2, 'Interview', 5],
      #     ['topics', 1, 'Music', 3],
      #     ['asset_type', 1, 'Segment', 9],
      #     ['contributing_organizations', 38, 'WGBH+(MA)', 6],
      #     ['producing_organizations', 4, 'KQED-TV (Television station : San Francisco, Calif.)', 1]
      #   ]

      # end


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
      target = PBCorePresenter.new(File.read('spec/fixtures/pbcore/' + fixture_name))
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
      # expect_all_the_text('clean-MOCK.xml')
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
      expect_audio(poster: '/thumbs/AUDIO.png')
    end

    it 'apologizes if no access' do
      visit '/catalog/cpb-aacip-80-12893j6c'
      # No need to click through
      expect_all_the_text('clean-bad-essence-track.xml')
      expect(page).to have_text('This content has not been digitized.'), missing_page_text_custom_error('This content has not been digitized.', page.current_path)
      expect_no_media
    end

    it 'links to collection' do
      visit '/catalog/cpb-aacip_111-21ghx7d6'
      expect(page).to have_text('This record is featured in'), missing_page_text_custom_error('This record is featured in', page.current_path)
      expect_video(poster: s3_thumb('cpb-aacip_111-21ghx7d6'))
    end

    it 'has a transcript if expected' do
      visit '/catalog/cpb-aacip_111-21ghx7d6'
      expect_transcript
    end

    # UHOH this wont work anymore
    it 'has no transcript if expected' do
      visit '/catalog/ccpb-aacip_508-g44hm5390k'
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
        expect(page).to have_text('only available at WGBH and the Library of Congress. '), missing_page_text_custom_error('only available at WGBH and the Library of Congress. ', page.current_path)
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

end

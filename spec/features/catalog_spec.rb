require 'rails_helper'
require 'resolv'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'
require_relative '../../scripts/lib/cleaner'
require_relative '../support/feature_test_helper'

# rubocop:disable Style/AlignParameters
describe 'Catalog' do
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

  describe 'catalog tests #index' do
    before(:all) do
      page.driver.options[:headers] = { 'REMOTE_ADDR' => '198.147.175.1' }

      PBCoreIngester.new.delete_all
      cleaner = Cleaner.instance

      @full_xml = build(:pbcore_description_document, :full_aapb, access_level_public: true, outside_url: true, external_reference_url: true, moving_image: true, iowa_org: true).to_xml

      # uses real guid to work with special collections, transcripts, etc
      @onloc_xml = build(:pbcore_description_document, :full_aapb, :only_episode_num_titles, has_transcript: true, access_level_protected: true).to_xml
      @spec_coll_xml = build(:pbcore_description_document, :full_aapb, :only_episode_num_titles, :in_special_collection, has_transcript: true, access_level_public: true, wgbh_org: true).to_xml

      @public_xml = build(:pbcore_description_document, :full_aapb, access_level_public: true, kqed_org: true, moving_image: true).to_xml
      @non_digi_xml = build(:pbcore_description_document, :full_aapb, :not_digitized).to_xml
      @audio_xml = build(:pbcore_description_document, :full_aapb, access_level_public: true, audio: true).to_xml

      [@full_xml, @onloc_xml, @spec_coll_xml, @public_xml, @non_digi_xml, @audio_xml].each do |xml|
        PBCoreIngester.ingest_record_from_xmlstring(xml)
      end

      @full_record = PBCorePresenter.new(cleaner.clean(@full_xml))
      @onloc_record = PBCorePresenter.new(cleaner.clean(@onloc_xml))
      @spec_coll_record = PBCorePresenter.new(cleaner.clean(@spec_coll_xml))
      @public_record = PBCorePresenter.new(cleaner.clean(@public_xml))
      @non_digi_record = PBCorePresenter.new(cleaner.clean(@non_digi_xml))
      @audio_record = PBCorePresenter.new(cleaner.clean(@audio_xml))
    end

    # dont need records
    it 'has facet messages' do
      visit '/catalog'
      expect(page).to have_text('Cataloging in progress: only half of the records for digitized assets are currently dated.'), missing_page_text_custom_error('Cataloging in progress: only half of the records for digitized assets are currently dated.', page.current_path)
    end

    it 'offers to broaden search' do
      visit '/catalog?q=xkcd&f[access_types][]=' + PBCorePresenter::PUBLIC_ACCESS
      expect(page).to have_text('No entries found'), missing_page_text_custom_error('No entries found', page.current_path)
      click_link 'searching all records'
      expect(page).to have_text('Consider using other search terms or removing filters.'), missing_page_text_custom_error('Consider using other search terms or removing filters.', page.current_path)
    end

    it 'has exhibit breadcrumb' do
      visit '/catalog?f[exhibits][]=station-histories&view=gallery&f[access_types][]=' + PBCorePresenter::ALL_ACCESS
      expect(page).to have_text('Documenting and Celebrating Public Broadcasting Station Histories'), missing_page_text_custom_error('Documenting and Celebrating Public Broadcasting Station Histories', page.current_path)
    end

    it 'has exhibit breadcrumb' do
      visit '/catalog?f[exhibits][]=station-histories&view=list&f[access_types][]=' + PBCorePresenter::ALL_ACCESS
      expect(page).to have_text('Documenting and Celebrating Public Broadcasting Station Histories'), missing_page_text_custom_error('Documenting and Celebrating Public Broadcasting Station Histories', page.current_path)
    end

    it 'has collection specific search panel' do
      visit '/catalog?f[special_collections][]=ken-burns-civil-war&view=list&f[access_types][]=' + PBCorePresenter::ALL_ACCESS
      expect(page).to have_text('Need Help Searching?'), missing_page_text_custom_error('Need Help Searching?', page.current_path)
    end

    # do need records
    it 'can find one item' do
      visit "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&q=id:#{@full_record.id}"
      expect(page.status_code).to eq(200)
      expect_count(1)
      expect(page).to have_text(@full_record.title), missing_page_text_custom_error(@full_record.title, page.current_path)
      expect_thumbnail(@full_record.id_for_s3)
    end

    it 'can facet by series title' do
      visit "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&f[series_titles][]=#{@full_record.titles['Series']}"
      expect(page).to have_text(@full_record.title)
    end

    it 'can facet by program title' do
      visit "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&f[program_titles][]=#{@full_record.titles['Program']}"
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

      # just kqed
      click_link('KQED (CA)')
      expect(page).to have_field('KQED__CA__KQED__CA_', checked: true)

      expect_count(1)
      expect(page).to have_text('You searched for: Access all Remove constraint Access: all '\
                                'Contributing Organizations KQED (CA) Remove constraint Contributing Organizations: KQED (CA)'), missing_page_text_custom_error('You searched for: Access all Remove constraint Access: all '\
                                'Contributing Organizations KQED (CA) Remove constraint Contributing Organizations: KQED (CA)', page.current_path)

      # now both
      click_link('WGBH (MA)')
      expect_count(2)
      expect(page).to have_text('You searched for: Access all Remove constraint Access: all '\
                                'Contributing Organizations KQED (CA) OR WGBH (MA) Remove constraint Contributing Organizations: KQED (CA) OR WGBH (MA)'), missing_page_text_custom_error('You searched for: Access all Remove constraint Access: all '\
                                'Contributing Organizations KQED (CA) OR WGBH (MA) Remove constraint Contributing Organizations: KQED (CA) OR WGBH (MA)', page.current_path)

      click_link('KQED (CA)')
      # now just wgbh
      expect_count(1)
      expect(page).to have_text('You searched for: Access all Remove constraint Access: all '\
                                'Contributing Organizations WGBH (MA) Remove constraint Contributing Organizations: WGBH (MA)'), missing_page_text_custom_error('You searched for: Access all Remove constraint Access: all '\
                                'Contributing Organizations WGBH (MA) Remove constraint Contributing Organizations: WGBH (MA)', page.current_path)

      all(:css, '.constraints-container a.remove').first.click # remove access all
      # If you attempt to remove the access facet, it redirects you to the default,
      # but the default depends on requestor's IP address.
      # TODO: set address in request.
      expect_count(1)
      expect(page).to have_text('You searched for: Contributing Organizations WGBH (MA) Remove constraint Contributing Organizations: WGBH (MA) '), missing_page_text_custom_error('You searched for: Contributing Organizations WGBH (MA) Remove constraint Contributing Organizations: WGBH (MA) ', page.current_path)

      click_link('Iowa Public Television (IA)')
      # TODO: check count when IP set in request.
      expect(page).to have_text('Contributing Organizations: WGBH (MA) OR Iowa Public Television (IA)'), missing_page_text_custom_error('Contributing Organizations: WGBH (MA) OR Iowa Public Television (IA)', page.current_path)
      expect(page).to have_text('WGBH (MA) OR Iowa Public Television (IA)')
    end

    it 'works' do
      visit "/catalog/#{@public_record.id}.pbcore"
      expect(page.status_code).to eq(200)
      expect(page.source).to eq(@public_record.xml)
      expect(page.response_headers['Content-Type']).to eq('text/xml; charset=utf-8')
    end

    # TODO: need a new fixture for this?
    # describe '.mods' do
    #   it 'works' do
    #     visit "/catalog/#{@public_record.id}.mods"
    #     expect(page.status_code).to eq(200)
    #     expect(page.source).to eq(@public_record.mods)
    #     expect(page.response_headers['Content-Type']).to eq('text/xml; charset=utf-8')
    #   end
    # end

    def expect_all_the_text(target)
      # target = PBCorePresenter.new(File.read('spec/fixtures/pbcore/' + fixture_name))
      # This text from the PBCore model is included in to_solr for
      # search purposes, but excluded from view.
      text_ignores = [target.ids].flatten

      # #text is only used for #to_solr, so it's private...
      # so we need the #send to get at it.
      target.send(:text).each do |field|
        # dont think we need this anymore
        field.gsub!('cpb-aacip_', 'cpb-aacip-') if field =~ /^cpb-aacip/ # TODO: Remove when we sort out ID handling.
        next if text_ignores.include?(field)
        # just for data generated by fixtures
        expect(page).to have_text(field)
      end
    end

    it 'has thumbnails if outside_url' do
      visit "/catalog/#{@full_record.id}"
      expect_all_the_text(@full_record)
      expect_thumbnail(@full_record.id_for_s3) # has media, but also has outside_url, which overrides.
      expect_no_media
      # this tests external reference url, not outside_url
      expect_external_reference
    end

    it 'has poster otherwise if media' do
      visit "catalog/#{@public_record.id}"
      expect_all_the_text(@public_record)
      expect_video(poster: s3_thumb(@public_record.id_for_s3))
    end

    it 'has default poster for audio only' do
      visit "catalog/#{@audio_record.id}"
      expect_all_the_text(@audio_record)
      expect_audio(poster: '/thumbs/AUDIO.png')
    end

    it 'apologizes if no access' do
      visit "/catalog/#{@non_digi_record.id}"
      # No need to click through
      expect_all_the_text(@non_digi_record)
      expect(page).to have_text('This content has not been digitized.'), missing_page_text_custom_error('This content has not been digitized.', page.current_path)
      expect_no_media
    end

    it 'links to collection' do
      # this ID is set manually in @spec_coll_record
      visit '/catalog/cpb-aacip_111-21ghx7d6'
      expect(page).to have_text('This record is featured in'), missing_page_text_custom_error('This record is featured in', page.current_path)
      expect_video(poster: s3_thumb('cpb-aacip_111-21ghx7d6'))
    end

    it 'has a transcript if expected' do
      # this ID is set manually in @spec_coll_record
      visit '/catalog/cpb-aacip_111-21ghx7d6'
      expect_transcript
    end

    it 'has no transcript if expected' do
      # this ID is set manually in @spec_coll_record
      visit '/catalog/ccpb-aacip_508-g44hm5390k'
      expect_no_transcript
    end

    # describe 'access control' do
    it 'has warning for non-us access' do
      ENV['RAILS_TEST_IP_ADDRESS'] = '0.0.0.0'
      visit "catalog/#{@public_record.id}"
      ENV.delete('RAILS_TEST_IP_ADDRESS')
      expect_all_the_text(@public_record)
      expect(page).to have_text('not available at your location.'), missing_page_text_custom_error('not available at your location.', page.current_path)
      expect_no_media
    end

    it 'has warning for off-site access' do
      ENV['RAILS_TEST_IP_ADDRESS'] = Resolv.getaddress('umass.edu')
      visit "catalog/#{@onloc_record.id}"
      ENV.delete('RAILS_TEST_IP_ADDRESS')

      # modal makes some text not visible? not really relevant to this test
      # expect_all_the_text(@onloc_record)
      expect(page).to have_text('only available at WGBH and the Library of Congress. '), missing_page_text_custom_error('only available at WGBH and the Library of Congress. ', page.current_path)
      expect_no_media
    end

    it 'requires click-thru for ORR items' do
      ENV['RAILS_TEST_IP_ADDRESS'] = Resolv.getaddress('umass.edu')
      visit "catalog/#{@public_record.id}"
      ENV.delete('RAILS_TEST_IP_ADDRESS')
      expect(page).to have_text('Online Reading Room Rules of Use'), missing_page_text_custom_error('Online Reading Room Rules of Use', page.current_path)
    end

    it 'should not have #playlist when not in playlist' do
      visit "/catalog/#{@public_record.id}"
      expect(page).not_to have_css('div#playlist')
    end
  end

  describe 'playlist functions' do
    before(:all) do
      PBCoreIngester.new.delete_all
      cleaner = Cleaner.instance

      @playlist_1_xml = build(:pbcore_description_document,
        titles: [
          build(:pbcore_title, value: 'just-here-for-cleaner')
        ],

        descriptions: [
          build(:pbcore_description, value: 'just-here-for-cleaner')
        ],

        identifiers: [
          build(:pbcore_identifier, source: 'Sony Ci', value: 'not-real-id-for-you1'),
          build(:pbcore_identifier, source: 'http://americanarchiveinventory.org', value: 'first-playlist-guy')
        ],
        annotations: [
          build(:pbcore_annotation, type: 'Playlist Group', value: 'nixonimpeachmentday2'),
          build(:pbcore_annotation, type: 'Playlist Order', value: '1'),
          build(:pbcore_annotation, type: 'Level of User Access', value: 'Online Reading Room')
        ]
      ).to_xml

      @playlist_2_xml = build(:pbcore_description_document,
        titles: [
          build(:pbcore_title, value: 'just-here-for-cleaner')
        ],

        descriptions: [
          build(:pbcore_description, value: 'just-here-for-cleaner')
        ],

        identifiers: [
          build(:pbcore_identifier, source: 'Sony Ci', value: 'not-real-id-for-you2'),
          build(:pbcore_identifier, source: 'http://americanarchiveinventory.org', value: 'second-playlist-guy')

        ],
        annotations: [
          build(:pbcore_annotation, type: 'Playlist Group', value: 'nixonimpeachmentday2'),
          build(:pbcore_annotation, type: 'Playlist Order', value: '2'),
          build(:pbcore_annotation, type: 'Level of User Access', value: 'Online Reading Room')
        ]
      ).to_xml

      @playlist_3_xml = build(:pbcore_description_document,
        titles: [
          build(:pbcore_title, value: 'just-here-for-cleaner')
        ],

        descriptions: [
          build(:pbcore_description, value: 'just-here-for-cleaner')
        ],

        identifiers: [
          build(:pbcore_identifier, source: 'Sony Ci', value: 'not-real-id-for-you3'),
          build(:pbcore_identifier, source: 'http://americanarchiveinventory.org', value: 'third-playlist-guy')
        ],
        annotations: [
          build(:pbcore_annotation, type: 'Playlist Group', value: 'nixonimpeachmentday2'),
          build(:pbcore_annotation, type: 'Playlist Order', value: '3'),
          build(:pbcore_annotation, type: 'Level of User Access', value: 'Online Reading Room')
        ]
      ).to_xml

      @ingested_records = []
      [@playlist_1_xml, @playlist_2_xml, @playlist_3_xml].each do |xml|
        PBCoreIngester.ingest_record_from_xmlstring(xml)
      end

      @playlist_1_record = PBCorePresenter.new(cleaner.clean(@playlist_1_xml))
      @playlist_2_record = PBCorePresenter.new(cleaner.clean(@playlist_2_xml))
      @playlist_3_record = PBCorePresenter.new(cleaner.clean(@playlist_3_xml))
    end

    it 'has both playlist navigation options when applicable' do
      visit "catalog/#{@playlist_2_record.id}"
      expect(page).to have_css('div#playlist')
      expect(page).to have_text('Part 3'), missing_page_text_custom_error('Part 3', page.current_path)
      expect(page).to have_text('Part 1'), missing_page_text_custom_error('Part 1', page.current_path)
    end

    it 'has next playlist navigation option when first item in playlist' do
      visit "catalog/#{@playlist_1_record.id}"
      expect(page).to have_css('div#playlist')
      expect(page).not_to have_text('Part 1')
      expect(page).to have_text('Part 2')
    end

    it 'has previous playlist navigation option when last item in playlist' do
      visit "catalog/#{@playlist_3_record.id}"
      expect(page).to have_css('div#playlist')
      expect(page).to have_text('Part 2'), missing_page_text_custom_error('Part 2', page.current_path)
    end
  end
end
# rubocop:enable Style/AlignParameters

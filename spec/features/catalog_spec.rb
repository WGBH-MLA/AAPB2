require 'rails_helper'
require 'resolv'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'
require_relative '../support/feature_test_helper'

describe 'Catalog' do
  IGNORE_FILE = Rails.root.join('spec/support/fixture-ignore.txt')

  let(:onsite_user) do
    instance_double(User, onsite?: true, aapb_referer?: false, embed?: false, authorized_referer?: false)
  end

  let(:offsite_user) do
    instance_double(User, onsite?: false, aapb_referer?: false, embed?: false, authorized_referer?: false)
  end

  before(:each) do
    # Default user is onsite
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(onsite_user)

    # Default REMOTE_ADDR
    page.driver.options[:headers] ||= {}
    page.driver.options[:headers]['REMOTE_ADDR'] ||= '198.147.175.1'

    # Stub transcript to avoid external calls
    allow_any_instance_of(TranscriptFile).to receive(:file_content).and_return(
      File.read('./spec/fixtures/transcripts/cpb-aacip-111-21ghx7d6-transcript.json')
    )
  end

  # ---------- helpers ----------
  def expect_count(count, page_text = "")
    case count
    when 0
      expect(page).to have_text('No entries found'), missing_page_text_custom_error('No entries found', page.current_path)
    when 1
      expect(page).to have_text('1 entry found'), missing_page_text_custom_error('1 entry found', page.current_path)
    else
      if page_text.present?
        page_text = page_text.scan(/1 - \d{1,5} of \d{1,5}/).first
      end
      expect(page).to have_text("1 - #{[count, 10].min} of #{count}"), missing_page_text_custom_error("1 - #{[count, 10].min} of #{count}", page.current_path, page_text)
    end
  end

  def expect_thumbnail(id)
    expect(page).to have_css("img[src='#{AAPB::S3_BASE}/thumbnail/#{id}.jpg']")
  end

  def expect_audio(opts = {})
    poster = opts[:poster]
    expect(page).not_to have_text('Online Reading Room Rules of Use')
    expect(page).to have_selector('audio')
    expect(page).to have_css("audio[poster='#{poster}']") if poster
  end

  def expect_video(opts = {})
    poster = opts[:poster]
    expect(page).not_to have_text('Online Reading Room Rules of Use')
    expect(page).to have_selector('video')
    expect(page).to have_css("video[poster='#{poster}']") if poster
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
      %w(
        Nova\; Gratuitous\ Explosions\; 3-2-1\; Kaboom!
        Date:\ 2000-01-01
        Producing\ Organization:\ WGBH
        Best\ episode\ ever!
        ).each do |field|
          expect(page).to have_text(field), missing_page_text_custom_error(field, page.current_path)
      end
      expect_thumbnail('cpb-aacip-1234')
    end
  end

  # ---------- .pbcore & .mods ----------
  describe '.pbcore' do
    it 'works' do
      visit '/catalog/cpb-aacip-1234.pbcore'
      expect(page.status_code).to eq(200)
      expect { ValidatedPBCore.new(page.source) }.not_to raise_error
      expect(page.response_headers['Content-Type']).to eq('text/xml; charset=utf-8')
    end
  end

  describe '.mods' do
    it 'works' do
      visit '/catalog/cpb-aacip-1234.mods'
      expect(page.status_code).to eq(200)
      expect(page.source).to eq(File.read(Rails.root + 'spec/fixtures/pbcore/clean-MOCK.mods'))
      expect(page.response_headers['Content-Type']).to eq('text/xml; charset=utf-8')
    end
  end

  # ---------- #show tests ----------
  describe '#show' do
    def expect_all_the_text(fixture_name)
      target = PBCorePresenter.new(File.read('spec/fixtures/pbcore/' + fixture_name))
      text_ignores = [target.ids].flatten
      target.send(:text).each do |field|
        field.gsub!('cpb-aacip_', 'cpb-aacip/') if field =~ /^cpb-aacip/
        next if text_ignores.include?(field)
        expect(page).to have_text(field)
      end
    end

    it '404s if given bad id' do
      visit '/catalog/thisaintreal'
      expect(page.status_code).to eq(404)
    end

    it 'has thumbnails if outside_urls' do
      visit '/catalog/cpb-aacip-1234'
      expect_thumbnail('cpb-aacip-1234')
      expect_no_media
      expect_external_reference
    end

    it 'has poster otherwise if media' do
      visit 'catalog/cpb-aacip_37-16c2fsnr'
      expect_all_the_text('clean-every-title-is-episode-number.xml')
      expect_video(poster: s3_thumb('cpb-aacip-37-16c2fsnr'))
    end

    it 'has default poster for audio' do
      visit 'catalog/cpb-aacip_169-9351chfc'
      expect_all_the_text('clean-audio-digitized.xml')
      expect_audio(poster: '/thumbs/AUDIO.png')
    end

    it 'apologizes if no access' do
      visit '/catalog/cpb-aacip-80-12893j6c'
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

    # ---------- access control tests ----------
    describe 'access control' do
      it 'has warning for non-us access' do
        ENV['RAILS_TEST_IP_ADDRESS'] = '0.0.0.0'
        visit 'catalog/cpb-aacip_37-16c2fsnr'
        ENV.delete('RAILS_TEST_IP_ADDRESS')
        
        expect_all_the_text('clean-every-title-is-episode-number.xml')
        expect(page).to have_text(
          'not available at your location.'
        ), missing_page_text_custom_error(
          'not available at your location.',
          page.current_path
        )
        expect_no_media
      end
    end

      it 'has warning for non-us access' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(offsite_user)
        ENV['RAILS_TEST_IP_ADDRESS'] = '0.0.0.0'
        visit 'catalog/cpb-aacip_37-16c2fsnr'
        ENV.delete('RAILS_TEST_IP_ADDRESS')
        expect(page).to have_text('not available at your location.'), missing_page_text_custom_error('not available at your location.', page.current_path)
        expect_no_media
      end

      it 'has warning for off-site access' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(offsite_user)
        ENV['RAILS_TEST_IP_ADDRESS'] = Resolv.getaddress('umass.edu')
        visit 'catalog/cpb-aacip_111-21ghx7d6'
        ENV.delete('RAILS_TEST_IP_ADDRESS')
        expect(page).to have_text('only available at GBH and the Library of Congress'), missing_page_text_custom_error('only available at GBH and the Library of Congress', page.current_path)
        expect_no_media
      end

      it 'requires click-thru for ORR items' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(offsite_user)
        ENV['RAILS_TEST_IP_ADDRESS'] = Resolv.getaddress('umass.edu')
        visit 'catalog/cpb-aacip_37-16c2fsnr'
        ENV.delete('RAILS_TEST_IP_ADDRESS')
        expect(page).to have_text('Online Reading Room Rules of Use'), missing_page_text_custom_error('Online Reading Room Rules of Use', page.current_path)
      end

      # Playlist tests remain unchanged
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

describe 'all fixtures' do
  Dir['spec/fixtures/pbcore/clean-*.xml'].each do |file_name|
    ignores = Set.new(File.readlines(IGNORE_FILE).map(&:strip))
    next if ignores.include?(file_name)

    pbcore = PBCorePresenter.new(File.read(file_name))
    id = pbcore.id
    describe id do
      details_url = "/catalog/#{id.gsub('/', '%2F')}"
      it "details: #{details_url}" do
        visit details_url
      end

      search_url = "/catalog?f[access_types][]=#{PBCorePresenter::ALL_ACCESS}&&q=#{id.gsub(/^(.*\W)?(\w+)$/, '\2')}"
      xit "search: #{search_url}" do
        visit search_url
        expect(page.status_code).to eq(200)
        expect_count(1, page.text)
      end
    end
  end
end

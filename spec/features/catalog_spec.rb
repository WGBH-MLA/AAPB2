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

      # Additional facet tests can remain as xit blocks for Blacklight coverage
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

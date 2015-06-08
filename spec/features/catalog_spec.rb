require 'rails_helper'
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
    url = "http://mlamedia01.wgbh.org/aapb/thumbnail/#{id}.jpg"
    expect(page).to have_css("img[src='#{url}']")
  end
  
  def expect_poster(id)
    url = "http://mlamedia01.wgbh.org/aapb/thumbnail/#{id}.jpg"
    expect(page).to have_css("video[poster='#{url}']")
  end

  describe '#index' do
    it 'can find one item' do
      visit '/catalog?search_field=all_fields&q=1234'
      expect(page.status_code).to eq(200)
      expect_count(1)
      [
        '3-2-1',
        'Kaboom!',
        'Gratuitous Explosions',
        'Series Nova',
        'uncataloged 2000-01-01',
        '2000-01-01',
        'Best episode ever!'
      ].each do |field|
        expect(page).to have_text(field)
      end
      expect_thumbnail(1234)
      expect_fuzzy_xml
    end

    describe 'search constraints' do
      describe 'title facets' do
        assertions = [
          ['f[series_titles][]=Nova', 1],
          ['f[program_titles][]=Gratuitous+Explosions', 1]
        ]
        assertions.each do |(param, count)|
          url = "/catalog?#{param}"
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
          url = "/catalog?search_field=all_fields#{params}"
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
          ['asset_type', 1, 'Segment', 5],
          ['organization', 1, 'WGBH+(MA)', 2],
          ['year', 1, '2000', 1],
          ['access_types', 2, 'All', 23]
        ]
        assertions.each do |facet, facet_count, value, value_count|
          url = "/catalog?f[#{facet}][]=#{value}"
          it "#{facet}=#{value}: #{value_count}\t#{url}" do
            visit url
            expect(
              page.all("#facet-#{facet} li").count
            ).to eq facet_count # expected number of values for each facet
            expect(
              page.all('.panel-heading[data-target]').map { |node|
                node['data-target'].gsub('#facet-', '')
              } - ['year'] # years are sparse, so they may drop out of the facet list.
            ).to eq(assertions.map { |a| a.first } - ['year']) # coverage
            expect(page.status_code).to eq(200)
            expect_count(value_count)
            expect_fuzzy_xml
          end
        end
      end

      describe 'fields' do
        assertions = [
          ['all_fields', 'Larry', 3],
          ['titles', 'Larry', 1],
          ['contribs', 'Larry', 1]
        ]
        assertions.each do |constraint, value, count|
          url = "/catalog?search_field=#{constraint}&q=#{value}"
          it "#{constraint}=#{value}: #{count}\t#{url}" do
            visit url
            expect(
              page.all('#search_field option').map { |node|
                node['value']
              }
            ).to eq(assertions.map { |a| a.first }) # coverage
            expect(page.status_code).to eq(200)
            expect_count(count)
            expect_fuzzy_xml
          end
        end
      end

      describe 'sorting' do
        assertions = [
          ['score+desc', 'Judd Hirsch'],
          ['year+desc', 'Kaboom!'],
          ['year+asc', 'Musical Encounter'],
          ['title+asc', 'World Youth Symphony Orchestra with Concerto Winners - Part II of II (261st program, 50th season)']
        ]
        assertions.each do |sort, title|
          url = "/catalog?search_field=all_fields&sort=#{sort}"
          it "sort=#{sort}: '#{title}'\t#{url}" do
            visit url
            expect(
              page.all('#sort-dropdown .dropdown-menu a').map { |node|
                node['href'].gsub(/.*sort=/, '')
              }
            ).to eq(assertions.map { |a| a.first }) # coverage
            expect(page.status_code).to eq(200)
            expect(page.find('.document[1] h2').text).to eq(title)
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
    it 'contains expected data' do
      visit '/catalog/1234'
      expect(page.status_code).to eq(200)
      target = PBCore.new(File.read('spec/fixtures/pbcore/clean-MOCK.xml'))
      target.send(:text).each do |field|
        # #text is only used for #to_solr, so it's private... 
        # so we need the #send to get at it.
        expect(page).to have_text(field)
      end
      expect_poster(1234)
    end
  end

  describe 'all fixtures' do
    Dir['spec/fixtures/pbcore/clean-*.xml'].each do |file_name|
      id = PBCore.new(File.read(file_name)).id
      describe id do
        details_url = "/catalog/#{id.gsub('/', '%2F')}" # Remember the URLs are tricky.
        it "details: #{details_url}" do
          visit details_url
          expect(page.status_code).to eq(200)
          expect_fuzzy_xml
        end
        search_url = "/catalog?search_field=all_fields&q=#{id.gsub(/^(.*\W)?(\w+)$/, '\2')}"
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

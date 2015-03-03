require 'rails_helper'
require_relative '../../scripts/lib/pb_core_ingester'
require_relative '../support/validation_helper'

describe 'Catalog' do

  include ValidationHelper

  before(:all) do
    # This is a test in its own right elsewhere.
    ingester = PBCoreIngester.new
    ingester.delete_all
    Dir['spec/fixtures/pbcore/clean-*.xml'].each do |pbcore|
      ingester.ingest(pbcore)
    end
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
    # TODO: "https://mlamedia01.wgbh.org/aapb/thumbnail/#{id}.jpg"
    # expect(page).to have_css("img[src='#{url}']")
  end

  describe '#index' do

    it 'can find one item' do
      visit '/catalog?search_field=all_fields&q=1234'
      expect(page.status_code).to eq(200)
      expect_count(1)
      [
        'Gratuitous Explosions',
        'Series NOVA',
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
          ['f[series_titles][]=NOVA', 1],
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
          ['', '.view-type-list.active'],
          ['&view=list', '.view-type-list.active'],
          ['&view=gallery', '.view-type-gallery.active']
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
          ['media_type', 'Sound', 6],
          ['genres', 'Interview', 3],
          ['asset_type', 'Segment', 5],
          ['organization', 'WGBH', 1],
          ['year', '2000', 1],
          ['access_types', 'All', 19]
        ]
        assertions.each_with_index do |(facet, value, count), index|
          url = "/catalog?f[#{facet}][]=#{value}"
          it "#{facet}=#{value}: #{count}\t#{url}" do
            visit url
            if index == 0
              expect(
                page.all('.panel-heading[data-target]').map { |node|
                  node['data-target'].gsub('#facet-', '')
                }
              ).to eq(assertions.map { |a| a.first }) # coverage
            end
            expect(page.status_code).to eq(200)
            expect_count(count)
            expect_fuzzy_xml
          end
        end
      end

      describe 'fields' do
        assertions = [
          ['all_fields', 'Larry', 2],
          ['titles', 'Larry', 1],
          ['contribs', 'Larry', 1]
        ]
        assertions.each_with_index do |(constraint, value, count), index|
          url = "/catalog?search_field=#{constraint}&q=#{value}"
          it "#{constraint}=#{value}: #{count}\t#{url}" do
            visit url
            if index == 0
              expect(
                page.all('#search_field option').map { |node|
                  node['value']
                }
              ).to eq(assertions.map { |a| a.first }) # coverage
            end
            expect(page.status_code).to eq(200)
            expect_count(count)
            expect_fuzzy_xml
          end
        end
      end

      describe 'sorting' do
        assertions = [
          ['score+desc', 'From Bessie Smith to Bruce Springsteen'],
          ['year+desc', 'Gratuitous Explosions'],
          ['title+asc', '#508']
        ]
        assertions.each_with_index do |(sort, title), index|
          url = "/catalog?search_field=all_fields&sort=#{sort}"
          it "sort=#{sort}: '#{title}'\t#{url}" do
            visit url
            if index == 0
              expect(
                page.all('#sort-dropdown .dropdown-menu a').map { |node|
                  node['href'].gsub(/.*sort=/, '')
                }
              ).to eq(assertions.map { |a| a.first }) # coverage
            end
            expect(page.status_code).to eq(200)
            expect(page.find('.document[1] .index_title').text).to eq(title)
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
      expect(page.source).to eq(File.read(File.dirname(File.dirname(__FILE__)) + '/fixtures/pbcore/clean-MOCK.xml'))
      expect(page.response_headers['Content-Type']).to eq('text/xml; charset=utf-8')
    end
  end

  describe '#show' do

    it 'contains expected data' do
      visit '/catalog/1234'
      expect(page.status_code).to eq(200)
      target = PBCore.new(File.read('spec/fixtures/pbcore/clean-MOCK.xml'))
      target.send(:text).each do |field|
        expect(page).to have_text(field)
      end

      expect_thumbnail(1234)
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

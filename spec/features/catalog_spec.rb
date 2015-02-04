require 'rails_helper'
require_relative '../../scripts/pb_core_ingester'

describe 'Catalog' do

  before(:all) do
    # This is a test in its own right elsewhere.
    ingester = PBCoreIngester.new
    ingester.delete_all
    Dir['spec/fixtures/pbcore/clean-*.xml'].each do |pbcore|
      ingester.ingest(pbcore)
    end
  end
  
  describe '#index' do
    
    it 'works' do
      visit '/catalog?search_field=all_fields&q=smith'
      expect(page.status_code).to eq(200)
      ['Media Type','Genre','Asset Type','Organization'].each do |facet|
        expect(page).to have_text(facet)
      end
      [
        'From Bessie Smith to Bruce Springsteen', 
        '1990-07-27', 
        'No description available'
      ].each do |field|
        expect(page).to have_text(field)
      end
    end
    
    describe 'facets' do
      [
        ['media_type','Sound',6],
        ['genre','Interview',3],
        ['asset_type','Segment',5],
        ['organization','WGBH',1],
        ['year','2000',1]
      ].each do |(facet,value,count)|
        url = "/catalog?f[#{facet}][]=#{value}"
        it "#{facet}=#{value}: #{count}\t#{url}" do
          visit url
          expect(page.status_code).to eq(200)
          expect_count(count)
        end
      end
    end
    
    describe 'fields' do
      [
        ['all_fields','Larry',2],
        ['title','Larry',1],
        ['contrib','Larry',1]
      ].each do |(constraint,value,count)|
        url = "/catalog?search_field=#{constraint}&q=#{value}"
        it "#{constraint}=#{value}: #{count}\t#{url}" do
          visit url
          expect(page.status_code).to eq(200)
          expect_count(count)
        end
      end
    end
    
    def expect_count(count)
      case count
      when 0
        expect(page).to have_text("No entries found")
      when 1
        expect(page).to have_text("1 entry found")
      else 
        expect(page).to have_text("1 - #{count} of #{count}")
      end
    end
    
  end
  
  describe '#show' do
    
    it 'contains expected data' do
      visit '/catalog/1234'
      expect(page.status_code).to eq(200)
      [
        'Gratuitous Explosions',
        'Series NOVA', 
        '1234 5678',
        'Best episode ever!',
        'explosions -- gratuitious', 'musicals -- horror',
        'Album',
        'uncataloged 2000-01-01',
        'Horror', 'Musical',
        'Moving Image',
        'WGBH',
        'Copy Left: All rights reversed.',
        'Moving Image', '0:12:34', 'Moving Image',
        'Contributor Curly, Stooges, bald',
        'Creator Larry, Stooges, balding',
        'Publisher Moe, Stooges, hair' 
      ].each do |field|
        expect(page).to have_text(field)
      end
    end
    
    describe 'for all fixtures' do
      # TODO: figure out how to just use the before-all to set this.
      Dir['spec/fixtures/pbcore/clean-*.xml'].each do |file_name|
        id = PBCore.new(File.read(file_name)).id
        url = "/catalog/#{id.gsub('/','%2F')}" # Remember the URLs are tricky.
        it "works for #{url}" do
          visit url
          expect(page.status_code).to eq(200)
        end
      end
    end
    
  end

end
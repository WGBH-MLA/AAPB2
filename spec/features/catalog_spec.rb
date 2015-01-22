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
    
  end
  
  describe '#show' do
    
    it 'works' do
      visit '/catalog/1234'
      expect(page.status_code).to eq(200)
      [
        'Gratuitous Explosions',
        'Documentary',
        '2000-01-01',
        'Horror', 'Musical',
        'Moving Image',
        'WGBH',
        'Copy Left: All rights reversed.'
      ].each do |field|
        expect(page).to have_text(field)
      end
    end
    
  end

end
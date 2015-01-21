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
      visit '/catalog?search_field=all_fields'
      expect(page.status_code).to eq(200)
      ['Media Type','Genre','Asset Type','Organization'].each do |facet|
        expect(page).to have_text(facet)
      end
      expect(page).to have_text('Gratuitous Explosions') # title: subject to paging.
    end
    
  end

end
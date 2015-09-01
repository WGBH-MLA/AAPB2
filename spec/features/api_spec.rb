require 'rails_helper'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'

describe 'API' do

  before(:all) do
    PBCoreIngester.load_fixtures
  end

  describe '#index' do
    it 'retrieves individual documents' do
      visit '/api.json?callback=callback&rows=1&q=id:1234&fl=id,title'
      expect(page).to have_text('callback({ "responseHeader"')
      expect(page).to have_text('"rows": "1"')
      expect(page).to have_text('Gratuitous Explosions')
    end

    it 'searches documents' do
      visit '/api.json?callback=callback&rows=10&q=iowa'
      expect(page).to have_text('callback({ "responseHeader"')
      expect(page).to have_text('"numFound": 3')
      expect(page).to have_text('Borlaug')
    end
    
    it 'supports facets for statistics' do
      visit '/api.json?callback=callback&facet=true&facet.field=year&' + 
        'facet.query[]=year:1988+AND+iowa'
      expect(page).to have_text('callback({ "responseHeader"')
      expect(page).to have_text('"rows": "0"')
      expect(page).to have_text('"year:1988 AND iowa": 1')
      expect(page).to have_text('"numFound": 24')
      expect(page).to have_text('"1981", 1, "1988", 1, "1990", 1, "2000", 1')
    end
  end
end

require 'rails_helper'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'
require_relative '../support/feature_test_helper'

describe 'API' do
  before(:all) do
    PBCoreIngester.load_fixtures
  end

  describe 'good queries' do
    it 'retrieves single pbcore docs' do
      visit '/api/cpb-aacip-1234.xml'
      expect(page.status_code).to eq 200
      expect(page.body).to match('<pbcoreDescriptionDocument')
    end

    it 'retrieves individual documents / default callback' do
      visit '/api.js?rows=1&q=id:cpb-aacip-1234&fl=id,title'
      expect(page.status_code).to eq 200
      expect(page).to have_text('callback({ "responseHeader"'), missing_page_text_custom_error('callback({ "responseHeader"', page.current_path)
      expect(page).to have_text('"rows": "1"'), missing_page_text_custom_error('"rows": "1"', page.current_path)
      expect(page).to have_text('Gratuitous Explosions'), missing_page_text_custom_error('Gratuitous Explosions', page.current_path)
    end

    it 'supports facets for statistics / explicit callback' do
      visit '/api.js?callback=my_callback&facet=true&facet.field=year&' \
            'facet.query[]=year:1988+AND+iowa'
      expect(page.status_code).to eq 200
      expect(page).to have_text('my_callback({ "responseHeader"'), missing_page_text_custom_error('my_callback({ "responseHeader"', page.current_path)
      expect(page).to have_text('"rows": "0"'), missing_page_text_custom_error('"rows": "0"', page.current_path)
      expect(page).to have_text('"year:1988 AND iowa": 1'), missing_page_text_custom_error('"year:1988 AND iowa": 1', page.current_path)
      expect(page).to have_text('"numFound": 46'), missing_page_text_custom_error('"numFound": 46', page.current_path)
      expect(page).to have_text('"1974", 4, "2007", 3, "1958", 2, "1987", 2, "1961", 1, "1981", 1, "1983", 1, "1988", 1, "1990", 1, "1992", 1, "2000", 1, "2003", 1, "2006", 1'), missing_page_text_custom_error('"1974", 4, "2007", 3, "1958", 2, "1987", 2, "1961", 1, "1981", 1, "1983", 1, "1988", 1, "1990", 1, "1992", 1, "2000", 1, "2003", 1, "2006", 1', page.current_path)
    end

    it 'searches documents / json, not jsonp' do
      visit '/api.json?rows=10&q=iowa'
      expect(page.status_code).to eq 200
      expect(page.source).to match(/^\{/s)
      expect(page).to have_text('"numFound": 6'), missing_page_text_custom_error('"numFound": 6', page.current_path)
      expect(page).to have_text('Norman Borlaug'), missing_page_text_custom_error('Norman Borlaug', page.current_path)
      expect(page.source).to match('"xml": "<pbcoreDescriptionDocument')
      # have_text runs the source through a regex that removes "tags",
      # even in non-xml documents.
    end

    it 'supports xml, too' do
      visit '/api.xml?rows=10&q=iowa'
      expect(page.status_code).to eq 200
      expect(page.source).to match('<numFound type="integer">6</numFound>')
      expect(page.source).to match('Norman Borlaug')
      expect(page.source).to match('<xml>&lt;pbcoreDescriptionDocument')
    end
  end

  describe 'error handling' do
    it 'has helpful error messages in json' do
      visit '/api.json?facet=error'
      expect(page.status_code).to eq 500
      expect(page).to have_text('"msg": "invalid boolean value: error"'), missing_page_text_custom_error('"msg": "invalid boolean value: error"', page.current_path)
    end

    it 'has helpful error messages in xml' do
      visit '/api.xml?facet=error'
      expect(page.status_code).to eq 500
      expect(page.source).to match('<msg>invalid boolean value: error</msg>')
    end
  end
end

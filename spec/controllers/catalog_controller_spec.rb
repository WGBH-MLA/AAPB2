# require_relative '../../app/controllers/application_controller'
# require_relative '../../app/controllers/catalog_controller'
require 'rails_helper'
describe CatalogController do
  describe 'redirection' do
    it 'not in effect if no params' do
      get 'index'
      expect(response.status).to eq 200
      expect(response).not_to redirect_to '/catalog'
    end

    it 'redirects if just blank q' do
      get 'index', q: ''
      expect(response).to redirect_to '/catalog'
    end

    it 'redirects if just blank f' do
      get 'index', f: {}
      expect(response).to redirect_to '/catalog'
    end

    it 'redirects if just blank q and blank f' do
      get 'index', q: '', f: {}
      expect(response).to redirect_to '/catalog'
    end

    it 'not in effect if q filled in, and access given' do
      get 'index', q: 'foo', f: {access_types: PBCore::ALL_ACCESS}
      expect(response.status).to eq 200
      expect(response).not_to redirect_to '/catalog'
    end

    it 'not in effect if f filled in' do
      get 'index', f: { year: 'data', access_types: PBCore::ALL_ACCESS }
      expect(response.status).to eq 200
      expect(response).not_to redirect_to '/catalog'
    end
    
    it 'errors if f is gibberish' do
      expect { get 'index', f: { gibberish: 'data', access_types: PBCore::ALL_ACCESS } }.to raise_error
      # TODO: This is the current behavior: do we want something different?
    end

    it 'not in effect if sort filled in' do
      get 'index', sort: 'year asc', f: {access_types: PBCore::ALL_ACCESS}
      expect(response.status).to eq 200
      expect(response).not_to redirect_to '/catalog'
    end
  end
end

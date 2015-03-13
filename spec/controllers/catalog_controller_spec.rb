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

    it 'not in effect if q filled in' do
      get 'index', q: 'foo'
      expect(response.status).to eq 200
      expect(response).not_to redirect_to '/catalog'
    end

    it 'not in effect if f filled in' do
      get 'index', f: { 'arbitrary' => 'data' }
      expect(response.status).to eq 200
      expect(response).not_to redirect_to '/catalog'
    end

    it 'not in effect if sort filled in' do
      get 'index', sort: 'year asc'
      expect(response.status).to eq 200
      expect(response).not_to redirect_to '/catalog'
    end
  end
end

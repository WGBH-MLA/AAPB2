# require_relative '../../app/controllers/application_controller'
# require_relative '../../app/controllers/catalog_controller'
require 'rails_helper'
describe CatalogController do
  describe 'redirection' do
    ACCESS = "&f[access_types][]=#{PBCore::PUBLIC_ACCESS}".freeze
    it 'redirects if no params' do
      get 'index'
      expect(response).to redirect_to '/catalog?' + ACCESS
    end

    it 'redirects if just blank q' do
      get 'index', q: ''
      expect(response).to redirect_to '/catalog?q=' + ACCESS
    end

    it 'redirects if just blank f' do
      get 'index', f: {}
      expect(response).to redirect_to '/catalog?' + ACCESS
    end

    it 'redirects if just blank q and blank f' do
      get 'index', q: '', f: {}
      expect(response).to redirect_to '/catalog?q=' + ACCESS
    end

    it 'redirects if sort filled in' do
      get 'index', sort: 'year asc'
      expect(response).to redirect_to '/catalog?sort=year+asc' + ACCESS
    end

    it 'supplies missing parameter' do
      get 'index', q: 'foo'
      expect(response).to redirect_to '/catalog?q=foo' + ACCESS
    end

    it 'not in effect if q filled in, and access given' do
      get 'index', q: 'foo', f: { access_types: PBCore::ALL_ACCESS }
      expect(response.status).to eq 200
    end

    it 'not in effect if f filled in' do
      get 'index', f: { year: 'data', access_types: PBCore::PUBLIC_ACCESS }
      expect(response.status).to eq 200
    end

    it 'errors if f is gibberish' do
      expect { get 'index', f: { gibberish: 'data', access_types: PBCore::ALL_ACCESS } }.to raise_error
      # TODO: This is the current behavior: do we want something different?
    end
  end
end

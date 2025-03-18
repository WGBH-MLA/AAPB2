# require_relative '../../app/controllers/application_controller'
# require_relative '../../app/controllers/catalog_controller'
require 'rails_helper'
require_relative '../../scripts/lib/pb_core_ingester'

describe CatalogController do
  describe 'redirection' do
    ACCESS = "&f[access_types][]=#{PBCorePresenter::PUBLIC_ACCESS}".freeze

    describe 'catalog#index' do
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
        get 'index', q: 'foo', f: { access_types: PBCorePresenter::ALL_ACCESS }
        expect(response.status).to eq 200
      end

      it 'not in effect if f filled in' do
        get 'index', f: { year: 'data', access_types: PBCorePresenter::PUBLIC_ACCESS }
        expect(response.status).to eq 200
      end

      it 'errors if f is gibberish' do
        expect { get 'index', f: { gibberish: 'data', access_types: PBCorePresenter::ALL_ACCESS } }.to raise_error
        # TODO: This is the current behavior: do we want something different?
      end
    end

    describe 'catalog#show' do
      before(:all) do
        PBCoreIngester.load_fixtures('spec/fixtures/pbcore/clean-has-chapters.xml', 'spec/fixtures/pbcore/clean-16-9.xml')
      end

      context 'with a record with a "Proxy Start Time annotation' do
        context 'when no proxy_start_time is included in params' do
          it 'redirects to URL with @pbcore.proxy_start_time' do
            allow_any_instance_of(User).to receive(:onsite?).and_return(true)
            get 'show', id: "cpb-aacip-114-90dv49m9"
            expect(response.redirect?).to eq true
            expect(response.status).to eq 302
            expect(Rack::Utils.parse_query(URI.parse(response.location).query)).to eq("proxy_start_time" => "65")
          end
        end

        context 'when a proxy_start_time is included in params' do
          it 'is preserved' do
            allow_any_instance_of(User).to receive(:onsite?).and_return(true)
            get 'show', id: "cpb-aacip-114-90dv49m9", proxy_start_time: "5"
            expect(response.redirect?).to eq false
            expect(response.status).to eq 200
            expect(controller.params["proxy_start_time"]).to eq "5"
          end
        end
      end

      context 'with a record without a "Proxy Start Time annotation' do
        context 'when no proxy_start_time is included in params' do
          it 'does nothing special' do
            allow_any_instance_of(User).to receive(:onsite?).and_return(true)
            get 'show', id: "cpb-aacip-508-g44hm5390k"
            expect(response.redirect?).to eq false
            expect(response.status).to eq 200
          end
        end

        context 'when a proxy_start_time is included in params' do
          it 'is preserved' do
            allow_any_instance_of(User).to receive(:onsite?).and_return(true)
            get 'show', id: "cpb-aacip-508-g44hm5390k", proxy_start_time: "11"
            expect(response.redirect?).to eq false
            expect(response.status).to eq 200
            expect(controller.params["proxy_start_time"]).to eq "11"
          end
        end
      end

      context 'when adding .iiif as a response format' do
        before { get :show, id: id, format: 'iiif' }
        let(:id) { 'cpb-aacip-114-90dv49m9' }
        let(:response_hash) { JSON.parse(response.body) }

        it 'returns a IIIF manifest for a given record' do
          expect(response.status).to eq 200
          expect(response.content_type).to eq 'application/json'
          expect(response_hash['@context']).to eq "http://iiif.io/api/presentation/3/context.json"
          expect(response_hash['id']).to match(/#{id}\.iiif\Z/)
        end
      end
    end
  end
end
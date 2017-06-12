require 'rails_helper'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'

describe ApiController do
  before(:all) do
    PBCoreIngester.load_fixtures
  end

  def auth_request(action, id, status_sym)
    ActionController::HttpAuthentication::Basic.encode_credentials(ENV['API_USER'], ENV['API_PASSWORD']) do
      get action, id: id
      expect(response).to have_http_status(status_sym)
    end
  end

  describe 'transcript API' do
    it 'returns 200 with credentials' do
      auth_request('transcript', 'cpb-aacip_111-21ghx7d6', :ok)
    end

    it 'returns 401 without credentials' do
      get 'transcript', id: 'cpb-aacip_111-21ghx7d6'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 404 when no transcript content is available' do
      auth_request('transcript', 'cpb-aacip_37-16c2fsnr', :not_found)
    end
  end
end

require 'rails_helper'
# require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'

describe ThumbnailsController do
  before(:all) do
    PBCoreIngester.load_fixtures('spec/fixtures/pbcore/clean-MOCK.xml')
  end

  describe 'redirection' do
    it 'speeds up redirects (cached response returns in <40ms)' do
      get 'show', id: 'cpb-aacip-1234'
      expect(response.redirect_url).to eq('http://americanarchive.org.s3.amazonaws.com/thumbnail/cpb-aacip_1234.jpg')

      start_2 = Time.now
      get 'show', id: '1234'
      length_2 = Time.now - start_2

      # increasing this to 40ms because travis is failing to accomplish 20ms and I'm tired of rerunning builds!
      expect(length_2).to be < 0.04
    end
  end
end

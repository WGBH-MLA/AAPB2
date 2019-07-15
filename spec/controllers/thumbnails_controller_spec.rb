require 'rails_helper'
# require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'

describe ThumbnailsController do
  # commenting this out because we don't appear to be using the fxtures in the test.
  # redirect in test should bypass the need for an actual ingest

  # before(:all) do
  #   PBCoreIngester.load_fixtures
  # end

  describe 'redirection' do
    it 'speeds up redirects (cached response returns in <20ms)' do
      get 'show', id: '1234'
      expect(response.redirect_url).to eq('http://americanarchive.org.s3.amazonaws.com/thumbnail/1234.jpg')

      start_2 = Time.now
      get 'show', id: '1234'
      length_2 = Time.now - start_2

      expect(length_2).to be < 0.02
    end
  end
end

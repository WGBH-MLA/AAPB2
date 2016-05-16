require 'rails_helper'
# require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'

describe ThumbnailsController do
  before(:all) do
    PBCoreIngester.load_fixtures
  end

  describe 'redirection' do
    it 'speeds up redirects' do
      start_1 = Time.now
      get 'show', id: '1234'
      length_1 = Time.now - start_1
      expect(response.redirect_url).to eq('http://americanarchive.org.s3.amazonaws.com/thumbnail/1234.jpg')

      start_2 = Time.now
      get 'show', id: '1234'
      length_2 = Time.now - start_2
      expect(length_1 > length_2 * 5).to be(true)
    end
  end
end

require 'rails_helper'
require_relative '../../scripts/lib/pb_core_ingester'

describe 'AMS' do
  before(:all) do
    PBCoreIngester.load_fixtures
  end

  describe '#show' do
    it 'works if media present' do
      visit '/ams/1234'
      expect(page.status_code).to eq(200)
      expect(page.body).to eq('<data><format>mp3</format><mediaurl>http://americanarchive.org/media/1234</mediaurl></data>')
    end

    it 'complains if media not present (using all dashes)' do
      visit '/ams/cpb-aacip-37-31cjt2qs'
      expect(page.status_code).to eq(404)
      expect(page.body).to eq('<error>No media file</error>')
    end

    it 'complains if the id is just wrong' do
      visit '/ams/no-such-id'
      expect(page.status_code).to eq(404)
      expect(page.body).to eq('<error>Bad ID</error>')
    end
  end
end

require 'rails_helper'
require_relative '../../scripts/lib/pb_core_ingester'

describe 'Embed' do
  
  before(:all) do
    PBCoreIngester.load_fixtures
  end

  it 'requires click-thru for ORR items' do
    ENV['RAILS_TEST_IP_ADDRESS'] = Resolv.getaddress('umass.edu')
    visit 'embed/cpb-aacip_37-16c2fsnr'
    expect(page.current_url).to match('/embed_terms/')
    click_button('I agree')
    ENV.delete('RAILS_TEST_IP_ADDRESS')
    expect(page).to have_css('video')
    expect(page.current_url).to match('/embed/')
  end
      
end
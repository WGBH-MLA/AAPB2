require 'rails_helper'
require_relative '../../scripts/lib/pb_core_ingester'

describe 'Embed' do
  before(:all) do
    PBCoreIngester.load_fixtures
  end

  it '/embed/[id] works' do
    visit 'embed/cpb-aacip_111-21ghx7d6'
    expect(page.status_code).to eq(200)
    expect(page).to have_css('video')
  end
end

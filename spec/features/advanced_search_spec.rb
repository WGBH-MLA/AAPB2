require 'rails_helper'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'

describe "Advanced Search Integration" do
  before(:all) do
    PBCoreIngester.load_fixtures
  end

  before(:each) do
    visit "/advanced?f[access_types][]=#{PBCore::ALL_ACCESS}"
  end

  it 'can do an exact search' do

    fill_in('exact', with: 'Rez')
    find('#advanced-search').click
    # records dont come up as they do when searching from client?
    expect(page).to have_text("Racing the Rez")
  end

  it 'can do a hybrid search' do
  end

  it 'can do an all these words search' do
  end
end

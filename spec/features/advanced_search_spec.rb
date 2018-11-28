require 'rails_helper'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'

describe "Advanced Search Integration" do
  before(:all) do
    PBCoreIngester.load_fixtures
  end

  before(:each) do
    visit '/advanced'
  end

  it 'can do an exact search' do

    fill_in('exact', with: 'Rez')
    find('#advanced-search').click

    require('pry');binding.pry
    expect some shit
  end

  it 'can do a hybrid search' do

  end

  it 'can do an all these words search' do
  end
end

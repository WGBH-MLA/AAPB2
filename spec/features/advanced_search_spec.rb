require 'rails_helper'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'
require_relative '../support/feature_test_helper'

describe 'Advanced Search Integration' do
  before(:all) do
    PBCoreIngester.load_fixtures
  end

  before(:each) do
    visit '/advanced?f[access_types][]=all'
  end

  it 'matches entire phrase for exact search' do
    fill_in('exact', with: 'Win or lose')
    find('#advanced-search').click
    expect(page).to have_text('Racing the Rez'), missing_page_text_custom_error('Racing the Rez', page.current_path)
    expect(page).to_not have_text('The Lost Year')
    expect(page).to_not have_text('The Civil War; Interviews with Barbara Fields')
    expect(page).to have_text('1 entry found'), missing_page_text_custom_error('1 entry found', page.current_path)
  end

  it 'searches with a mix of exact and other search terms' do
    fill_in('all', with: 'rez')
    fill_in('title', with: 'racing')
    fill_in('exact', with: 'runners')
    fill_in('any', with: 'vision')
    fill_in('none', with: 'artichoke')
    find('#advanced-search').click
    expect(page).to have_text('Racing the Rez'), missing_page_text_custom_error('Racing the Rez', page.current_path)
  end

  it 'enforces "none of these words" searches' do
    fill_in('all', with: 'rez')
    fill_in('exact', with: 'runners')
    fill_in('any', with: 'vision')
    fill_in('none', with: 'racing')
    find('#advanced-search').click
    expect(page).to_not have_text('Racing the Rez')
    expect(page).to have_text('No entries found'), missing_page_text_custom_error('No entries found', page.current_path)
  end
end

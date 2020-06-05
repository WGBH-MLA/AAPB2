require 'rails_helper'
require_relative '../support/feature_test_helper'

describe 'Organizations' do
  it 'has expected content on #index' do
    visit '/participating-orgs'
    expect(page.status_code).to eq(200)
    expect(page).to have_text('Participating Organizations'), missing_page_text_custom_error('Participating Organizations', page.current_path)
    expect(page).to have_text('WGBH'), missing_page_text_custom_error('WGBH', page.current_path)
    expect(page).to have_text('Boston, Massachusetts'), missing_page_text_custom_error('Boston, Massachusetts', page.current_path)

    expect(page).to have_xpath('//a[@href="/participating-orgs/1784.2"]')
  end

  it 'has expected content on #show' do
    visit '/participating-orgs/1784.2'
    expect(page.status_code).to eq(200)
    expect(page).to have_text('WGBH'), missing_page_text_custom_error('WGBH', page.current_path)
    expect(page).to have_text('Boston, Massachusetts'), missing_page_text_custom_error('Boston, Massachusetts', page.current_path)
    # TODO: when WGBH has more content, make sure it shows up.

    expect(page).not_to have_text('WGBY')
    # Has ID "1784": We want to be sure Rails is not ignoring the ".2".

    expect(page).to have_xpath('//a[@href="/catalog?f[contributing_organizations][]=WGBH+%28MA%29"]')
  end
end

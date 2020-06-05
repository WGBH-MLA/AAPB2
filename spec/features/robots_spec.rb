require 'rails_helper'
require_relative '../support/feature_test_helper'

describe 'robots.txt' do
  it 'has a Disallow' do
    visit '/robots.txt'
    expect(page.status_code).to eq(200)
    expect(page).to have_text('Disallow: '), missing_page_text_custom_error('Disallow: ', page.current_path)
  end
end

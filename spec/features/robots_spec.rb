require 'rails_helper'
require_relative '../support/validation_helper'

describe 'robots.txt' do
  it 'has a Disallow' do
    visit '/robots.txt'
    expect(page.status_code).to eq(200)
    expect(page).to have_text("Disallow: /\n")
  end
end

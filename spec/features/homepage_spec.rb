require 'rails_helper'

describe 'Homepage' do

  it 'works' do
    visit '/'
    expect(page.status_code).to eq(200)
    expect(page).to have_text('Search over 40,000 hours of publicly funded broadcasting in America.')
  end

end
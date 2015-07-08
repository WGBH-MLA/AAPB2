require 'rails_helper'
require_relative '../support/validation_helper'

describe 'Exhibits' do
  it '/exhibits works' do
    visit '/exhibits'
    expect(page.status_code).to eq(200)
    expect_fuzzy_xml
  end
  
  Exhibit.all.each do |exhibit|
    path = "/exhibits/#{exhibit.path}"
    it "#{path} works" do
      visit path
      expect(page.status_code).to eq(200)
      expect_fuzzy_xml
    end
  end
end

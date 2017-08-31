require 'rails_helper'
require_relative '../support/validation_helper'

describe 'Special Collections' do
  it '/special_collections works' do
    visit '/special_collections'
    expect(page.status_code).to eq(200)
    expect_fuzzy_xml
  end

  SpecialCollection.all.each do |coll|
    path = "/special_collections/#{coll.path}"
    it "#{path} works" do
      visit path
      expect(page.status_code).to eq(200)
      expect_fuzzy_xml
    end
  end
end

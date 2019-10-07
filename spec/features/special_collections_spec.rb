require 'rails_helper'

describe 'Special Collections' do
  it '/special_collections works' do
    visit '/special_collections'
    expect(page.status_code).to eq(200)
  end

  SpecialCollection.all.each do |coll|
    path = "/special_collections/#{coll.path}"
    it "#{path} works" do
      visit path
      expect(page.status_code).to eq(200)
    end
  end
end

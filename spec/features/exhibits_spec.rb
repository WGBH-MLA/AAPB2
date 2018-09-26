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

  it 'gets all components of a gallery item' do

    # TODO: change this to a real exhibit once they're all reformatted
    visit '/exhibits/exampleexhibit'
    expect page.find(:css, 'div.exgal-1 div.exgal-caption').to have_content "This is the caption text for the first gallery item."
    expect page.find(:css, 'div.exgal-1 div.exgal-source').to have_content "Courtesy: First Source name"
  end

end

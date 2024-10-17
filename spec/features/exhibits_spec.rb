require 'rails_helper'

describe 'Exhibits' do
  it '/exhibits works' do
    visit '/exhibits'
    expect(page.status_code).to eq(200)
  end

  Exhibit.all.each do |exhibit|
    path = "/exhibits/#{exhibit.path}"
    it "#{path} works" do
      visit path
      expect(page.status_code).to eq(200)
    end
  end

  it 'gets all components of a gallery item' do
    # TODO: change this to a real exhibit once they're all reformatted
    visit '/exhibits/civil-rights'
    expect(page.find(:css, 'div.exgal-1 div.exgal-caption')).to have_content 'Voices from the Southern Civil Rights Movement'
  end
end

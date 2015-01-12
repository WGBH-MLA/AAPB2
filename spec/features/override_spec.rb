require 'rails_helper'

describe "Overrides" do

  describe "About" do
    it "works" do
      visit '/about'
      expect(page.status_code).to eq(200)
      expect(page).to have_text('TODO: about page')
    end
  end

end
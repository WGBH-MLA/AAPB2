require 'rails_helper'

describe 'Organizations' do

  describe '#index' do
    it 'works' do
      visit '/organizations'
      expect(page.status_code).to eq(200)
      expect(page).to have_text('TODO: organizations list')
    end
  end
  
  describe '#show' do
    it 'works' do
      visit '/organizations/WGBH'
      expect(page.status_code).to eq(200)
      expect(page).to have_text('TODO: one organization')
    end
  end

end
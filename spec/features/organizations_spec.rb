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
      visit '/organizations/1784.2'
      expect(page.status_code).to eq(200)
      expect(page).to have_text('TODO: one organization')
      expect(page).to have_text('WGBH')
    end
  end

end
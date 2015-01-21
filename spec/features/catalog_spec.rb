require 'rails_helper'

describe 'Catalog' do

  describe '#index' do
    
    it 'works' do
      visit '/catalog?search_field=all_fields'
      expect(page.status_code).to eq(200)
      ['Media Type','Genre','Asset Type','Organization'].each do |facet|
        expect(page).to have_text(facet)
      end
      expect(page).to have_text('Gratuitous Explosions') # title: subject to paging.
    end
    
  end

end
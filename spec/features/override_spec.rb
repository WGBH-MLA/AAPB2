require 'rails_helper'
require_relative '../support/validation_helper'

describe 'Overrides' do
  Dir['app/views/override/**'].each do |override|
    path = override.gsub('app/views/override', '').gsub('.html.erb', '')

    it "#{path} works" do
      visit path
      expect(page.status_code).to eq(200)
      expect_fuzzy_xml
    end
  end
end

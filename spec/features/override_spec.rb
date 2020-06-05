require 'rails_helper'

describe 'Overrides' do
  Dir['app/views/override/**/*']
    .reject { |file| File.directory?(file) }
    .reject { |file| file.match(/\.erb$/) }
    .each do |override|
      path = override.gsub(/app\/views(\/override)?/, '').sub('.md', '')

      it "#{path} method works" do
        visit path
        expect(page.status_code).to eq(200)
        expect(page.all('input[name="path"]').count).to eq(0)
      end
    end
end

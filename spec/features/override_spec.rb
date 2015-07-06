require 'rails_helper'
require_relative '../support/validation_helper'

describe 'Overrides' do
  ['override', 'exhibits'].each do |dir|
    Dir["app/views/#{dir}/**/*"].
      reject { |file| File.directory?(file) }.
      reject { |file| file.match(/\.erb$/)}.
      each do |override|
        path = override.gsub(/app\/views(\/override)?/, '').sub('.md', '')

        it "#{path} works" do
          visit path
          expect(page.status_code).to eq(200)
          expect(page.all('input[name="path"]').count).to eq(0)
          expect_fuzzy_xml
        end
      end
  end
end

require 'rails_helper'
require_relative '../../scripts/lib/pb_core_ingester'
require_relative '../support/feature_test_helper'

describe 'Transcripts' do
  #  include ValidationHelper

  # commenting this out because we don't appear to be using the fxtures in the test.
  # before(:all) do
  #   PBCoreIngester.load_fixtures
  # end

  # xit due to fact we re-organized Captions and Transcripts
  describe '#show' do
    xit 'renders SRT as HTML' do
      visit '/transcripts/1234'
      expect(page).to have_text('Raw bytes 0-255 follow'), missing_page_text_custom_error('Raw bytes 0-255 follow', page.current_path)
    end
  end
end

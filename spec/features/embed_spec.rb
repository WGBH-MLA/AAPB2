require 'rails_helper'
require_relative '../../scripts/lib/pb_core_ingester'

describe 'Embed' do
  before do
    # random indiana IP
    page.driver.options[:headers] = { 'REMOTE_ADDR' => '168.214.152.244' }

    PBCoreIngester.load_fixtures(
      # ID of this record is 'cpb-aacip_moving-image_public'
      'spec/fixtures/pbcore/clean-moving-image-public.xml',
      # ID of this record is 'cpb-aacip_moving-image_protected'
      'spec/fixtures/pbcore/clean-moving-image-protected.xml',
      # ID of this record is 'cpb-aacip_moving-image_private'
      'spec/fixtures/pbcore/clean-moving-image-private.xml'
    )

    allow_any_instance_of(User).to receive(:usa?).and_return(true)
  end

  context 'when record is public' do
    before { visit 'embed/cpb-aacip_moving-image-public' }
    it 'shows the video player' do
      expect(page).to have_css('video')
    end
  end

  context 'when record is protected' do
    before { visit 'embed/cpb-aacip_moving-image-protected' }
    it 'does not show the video player' do
      expect(page).not_to have_css('video')
      expect(page).to have_content "This content is only available at WGBH and the Library of Congress."
    end
  end

  context 'when record is private' do
    before { visit 'embed/cpb-aacip_moving-image-private' }
    it 'does not show the video player' do
      expect(page).not_to have_css('video')
      expect(page).to have_content "This content is only available at the Library of Congress."
    end
  end
end

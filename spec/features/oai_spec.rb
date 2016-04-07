require 'rails_helper'
require_relative '../../scripts/lib/pb_core_ingester'

describe 'OAI-PMH' do
  before(:all) do
    PBCoreIngester.load_fixtures
  end

  it 'loads the index page' do
    visit '/oai.xml?verb=ListRecords'
    expect(page.status_code).to eq(200)
    expect { REXML::Document.new(page.body) }.not_to raise_error
    [
      '<OAI-PMH', # Followed by NS
      '<request verb="ListRecords" metadataPrefix="pbcore">http://openvault.wgbh.org/oai.xml</request>',
      '<ListRecords>',
      '<identifier>A_00000000_MOCK</identifier>',
      '<pbcoreDescriptionDocument', # Followed by NS
      '<pbcoreIdentifier source="Open Vault UID">A_00000000_MOCK</pbcoreIdentifier>'
    ].each do |s|
      expect(page.body).to match s
    end
  end
end

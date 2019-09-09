require 'rails_helper'
require_relative '../../scripts/lib/pb_core_ingester'

describe 'OAI-PMH' do
  before(:all) do
    @public_xml = just_xml(build(:pbcore_description_document, :full_aapb, access_level_public: true, kqed_org: true, moving_image: true))

    PBCoreIngester.new.delete_all
    cleaner = Cleaner.instance
    PBCoreIngester.ingest_record_from_xmlstring(@public_xml)
    @public_record = PBCorePresenter.new(cleaner.clean(@public_xml))
  end

  it 'loads the index page' do
    visit '/oai.xml?verb=ListRecords'
    expect(page.status_code).to eq(200)
    expect { REXML::Document.new(page.body) }.not_to raise_error
    [
      '<OAI-PMH', # Followed by NS
      '<request verb="ListRecords" metadataPrefix="mods">http://openvault.wgbh.org/oai.xml</request>',
      '<ListRecords>',
      %(<identifier type="uri">http://americanarchive.org/catalog/#{@public_record.id}</identifier>)
    ].each do |s|
      expect(page.body).to match s
    end
  end
end

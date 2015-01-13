require_relative '../../scripts/pb_core_ingester'

describe PBCoreIngester do
  
  let(:ingester) {PBCoreIngester.new}
  
  it 'fails with non-existent file' do
    expect{ingester.ingest('/non-existent.xml')}.to raise_error(PBCoreIngester::ReadError)
  end
  
  it 'fails with invalid file' do
    # obviously this file is not valid pbcore.
    expect{ingester.ingest(__FILE__)}.to raise_error(PBCoreIngester::ValidationError)
  end
  
  it 'fails when the ingester is not pointing at solr' do
    bad_ingester = PBCoreIngester.new('bad-protocol:bad-host')
    good_path = File.dirname(File.dirname(__FILE__))+'/fixtures/pbcore/clean-MOCK.xml'
    expect{bad_ingester.ingest(good_path)}.to raise_error(PBCoreIngester::SolrError)
  end
  
end
  
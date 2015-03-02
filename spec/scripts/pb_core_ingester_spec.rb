require_relative '../../scripts/lib/pb_core_ingester'
require 'tmpdir'

describe PBCoreIngester do
  
  let(:path) {File.dirname(File.dirname(__FILE__))+'/fixtures/pbcore/clean-MOCK.xml'}
  
  before(:each) do
    @ingester = PBCoreIngester.new
    @ingester.delete_all
  end
  
  it 'fails with non-existent file' do
    expect { @ingester.ingest('/non-existent.xml') }.to raise_error(PBCoreIngester::ReadError)
  end
  
  it 'fails with invalid file' do
    # obviously this file is not valid pbcore.
    expect { @ingester.ingest(__FILE__) }.to raise_error(PBCoreIngester::ValidationError)
  end
  
  it 'fails when the ingester is not pointing at solr' do
    bad_ingester = PBCoreIngester.new('bad-protocol:bad-host')
    expect { bad_ingester.ingest(path) }.to raise_error(PBCoreIngester::SolrError)
  end
  
  it 'works for single ingest' do
    expect_results(0)
    expect { @ingester.ingest(path)}.not_to raise_error
    expect_results(1)
    expect { @ingester.ingest(path)}.not_to raise_error
    expect_results(1)
    expect { @ingester.delete_all}.not_to raise_error
    expect_results(0)
  end
  
  it 'works for collection' do
    Dir.mktmpdir do |dir|
      expect_results(0)
      document = File.read(path)
      collection = "<pbcoreCollection>#{document}</pbcoreCollection>"
      collection_path = "#{dir}/collection.xml"
      File.write(collection_path, collection)
      expect { @ingester.ingest(collection_path)}.not_to raise_error
      expect_results(1)
      expect { @ingester.delete_all}.not_to raise_error
      expect_results(0)
    end
  end
  
  it 'works for all fixtures' do
    expect_results(0)
    glob = File.dirname(path)+'/clean-*'
    Dir[glob].each do |fixture_path|
      expect { @ingester.ingest(fixture_path)}.not_to raise_error
    end
    expect_results(19)
  end
  
  def expect_results(count)
    expect(@ingester.solr.get('select', params: {q: '*:*'})['response']['numFound']).to eq(count)
  end
  
end
  
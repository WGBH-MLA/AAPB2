require_relative '../../scripts/lib/pb_core_ingester'
require 'tmpdir'

describe PBCoreIngester do
  let(:path) { Rails.root + 'spec/fixtures/pbcore/clean-MOCK.xml' }

  before(:each) do
    @ingester = PBCoreIngester.new
    @ingester.delete_all
  end

  it 'whines about non-existent file' do
    @ingester.ingest(path: '/non-existent.xml')
    expect(@ingester.errors.keys).to eq ['Errno::ENOENT: No such file or directory @ rb_sysopen - /non-existent.xml']
  end

  it 'whines about invalid file' do
    @ingester.ingest(path: __FILE__)
    expect(@ingester.errors.keys).to eq ['PBCoreIngester::ValidationError: Neither pbcoreCollection nor pbcoreDocument. require_relative \'../../scripts/lib/pb_core_ingester\'']
  end

  it 'works for single ingest' do
    expect_results(0)
    expect { @ingester.ingest(path: path) }.not_to raise_error
    expect_results(1)
    expect { @ingester.ingest(path: path) }.not_to raise_error
    expect_results(1)
    expect { @ingester.delete_all }.not_to raise_error
    expect_results(0)
  end

  it 'works for collection' do
    Dir.mktmpdir do |dir|
      expect_results(0)
      document = File.read(path)
      collection = "<pbcoreCollection>#{document}</pbcoreCollection>"
      collection_path = "#{dir}/collection.xml"
      File.write(collection_path, collection)
      expect { @ingester.ingest(path: collection_path) }.not_to raise_error
      expect_results(1)
      expect { @ingester.delete_all }.not_to raise_error
      expect_results(0)
    end
  end

  it 'works for all fixtures' do
    expect_results(0)
    glob = File.dirname(path) + '/clean-*'
    Dir[glob].each do |fixture_path|
      expect { @ingester.ingest(path: fixture_path) }.not_to raise_error
    end
    expect_results(43)
  end

  def expect_results(count)
    expect(Solr.instance.connect.get('select', params: { q: '*:*' })['response']['numFound']).to eq(count)
  end
end

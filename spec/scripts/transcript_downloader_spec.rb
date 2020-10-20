require 'rails_helper'
require_relative '../../lib/aapb'
require_relative '../../scripts/lib/pb_core_ingester'
require_relative '../../scripts/transcript_downloader'
require 'tmpdir'
require 'fileutils'

describe TranscriptDownloader do

  before(:all) do
    PBCoreIngester.load_fixtures
  end

  after(:all) do
    Solr.instance.connect.delete_by_query('*:*')
    FileUtils.rm_rf('tmp/downloads/transcripts/spec')
  end

  let(:transcript_downloader) { TranscriptDownloader.new(contributing_organization: 'Appalshop, Inc. (KY)', dir: 'tmp/downloads/transcripts/spec' ) }

  it '#initialize' do
    expect(transcript_downloader.solr_docs.first['id']).to eq('cpb-aacip-138-74cnpdc8')
    expect(transcript_downloader.contributing_organization).to eq('Appalshop, Inc. (KY)')
    expect(transcript_downloader.dir).to eq('tmp/downloads/transcripts/spec')

  end

  it '#download' do
    transcript_downloader.download
    files = Dir.entries(Rails.root + 'tmp/downloads/transcripts/spec').select{ |x| x.match(/Appalshop-Inc-KY-transcripts.zip/)  }
    expect(files.length).to eq(1)
  end

end

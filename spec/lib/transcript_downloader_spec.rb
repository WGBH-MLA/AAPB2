require 'rails_helper'
require_relative '../../lib/transcript_downloader'
require 'fileutils'

describe TranscriptDownloader do
  after(:all) do
    FileUtils.rm_rf('tmp/downloads/transcripts/spec')
  end

  before(:each) do
    xml = File.read('./spec/fixtures/pbcore/clean-transcript.xml')

    allow_any_instance_of(RSolr::Client).to receive(:get).and_return(
      "responseHeader" => { "status" => 0, "QTime" => 1, "params" => { "q" => "contributing_organizations:\"Appalshop, Inc. (KY)\"", "wt" => "ruby" } }, "response" => { "numFound" => 1, "start" => 0, "docs" => [{ "id" => "cpb-aacip-138-74cnpdc8", "xml" => xml, "title" => "Musical Performance of Appalachian Folk Music in Kentucky", "asset_date" => "1992-06-05T00:00:00Z", "playlist_order" => "0", "timestamp" => "2020-10-20T17:43:38.493Z" }] }
    )
  end

  let(:transcript_downloader) { TranscriptDownloader.new(contrib: 'Appalshop, Inc. (KY)', dir: 'tmp/downloads/transcripts/spec') }

  it '#initialize' do
    expect(transcript_downloader.solr_docs.first['id']).to eq('cpb-aacip-138-74cnpdc8')
    expect(transcript_downloader.contrib).to eq('Appalshop, Inc. (KY)')
    expect(transcript_downloader.dir).to eq('tmp/downloads/transcripts/spec')
  end

  it '#download' do
    transcript_downloader.download
    files = Dir.entries(Rails.root + 'tmp/downloads/transcripts/spec').select { |file| file.match(/Appalshop-Inc-KY-transcripts.zip/) }
    expect(files.length).to eq(1)
  end
end

require 'rails_helper'
require_relative '../../lib/transcript_downloader'
require 'fileutils'

describe CiToAWSTransfer do

  before(:each) do
    xml = File.read('./spec/fixtures/pbcore/clean-playlist-3.xml')

    allow_any_instance_of(RSolr::Client).to receive(:get).and_return(
      "responseHeader" => { "status" => 0, "QTime" => 1, "params" => { "q" => "", "wt" => "ruby" } }, "response" => { "numFound" => 1, "start" => 0, "docs" => [{ "id" => "cpb-aacip-512-w66930pv96", "xml" => xml, "title" => "Nixon Impeachment Hearings; 2; 1974-07-24; Part 3 of 3", "asset_date" => "1974-07-24T00:00:00Z", "playlist_order" => "3", "timestamp" => "2020-12-21T17:00:31.208Z" }] }
    )
  end

  let(:aws_transfer) { CiToAWSTransfer.new(query: '') }

  it '#initialize' do
    expect{ CiToAWSTransfer.new }.to raise_error(RuntimeError, /query cannot be nil/)
    expect(aws_transfer.solr_docs.first['id']).to eq("cpb-aacip-512-w66930pv96")
    expect(aws_transfer.ci).to be_an_instance_of(SonyCiBasic)
    expect(aws_transfer.aws_client).to be_an_instance_of(Aws::S3::Client)
  end


end

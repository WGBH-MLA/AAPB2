require 'rails_helper'
require_relative '../../lib/transcript_downloader'
require 'fileutils'

# TODO: Using the new Sony Ci API gem broke this spec, but the subject of the
# spec may no longer be needed. It appears to be lib used only from the cmdline
# and for a one-off workflow. But need to verify that before removing
# completely.
describe CiToAWSTransfer, skip: true do
  before(:each) do
    xml = File.read('./spec/fixtures/pbcore/clean-playlist-3.xml')

    allow_any_instance_of(RSolr::Client).to receive(:get).and_return(
      "responseHeader" => { "status" => 0, "QTime" => 1, "params" => { "q" => "", "wt" => "ruby" } }, "response" => { "numFound" => 1, "start" => 0, "docs" => [{ "id" => "cpb-aacip-512-w66930pv96", "xml" => xml, "title" => "Nixon Impeachment Hearings; 2; 1974-07-24; Part 3 of 3", "asset_date" => "1974-07-24T00:00:00Z", "playlist_order" => "3", "timestamp" => "2020-12-21T17:00:31.208Z" }] }
    )

    ci_instance = instance_double("SonyCiBasic", download: "https://www.sonyci.com/this-is-a-download-url")
    allow(SonyCiBasic).to receive(:new).with(credentials_path: Rails.root + 'config/ci.yml').and_return(ci_instance)

    aws_client_instance = instance_double("Aws::S3::Client")
    allow(Aws::S3::Client).to receive(:new).and_return(aws_client_instance)
  end

  describe '#initialize' do
    context 'without expected params' do
      let(:aws_transfer) { CiToAWSTransfer.new(query: '') }

      it 'raises an error' do
        expect { CiToAWSTransfer.new }.to raise_error(RuntimeError, /query cannot be nil/)
      end
    end

    context 'with params' do
      let(:aws_transfer) { CiToAWSTransfer.new(query: 'things:thing') }

      it 'has an expected path attribute' do
        expect(aws_transfer.path).to match(/tmp\/downloads\/\d{4}-\d{2}-\d{2}_sony_ci_downloads/)
      end
    end
  end
end

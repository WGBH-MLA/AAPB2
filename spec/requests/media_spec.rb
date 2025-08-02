require 'rails_helper'
require_relative '../../scripts/lib/pb_core_ingester'
require 'support/sony_ci_api_helpers'

describe 'Requests to /media/ endpoints', not_on_ci: true, type: :request do
  # Test Setup - several things going on in here, see comments for details.
  before(:all) do
    # Exhibits take forever to load during ingest of test record. This monkey
    # patch to the CMLess class makes it look like there aren't any to load.
    # Exhibits are irrelevant for these tests so this is ok.
    def Exhibit.each
      []
    end

    # This fake ID corresponds with a media file in spec/fixtures/media/.
    # We store it in an instance variable so we can delete in the `after` block.
    @aapb_id = 'cpb-aacip-123-456789'
    result = sony_ci.upload("spec/fixtures/media/#{@aapb_id}.mp4", content_type: 'video/mp4')

    # Raise an error if the upload failed.
    raise "Sony Ci Failed to upload to test workspace" unless result['assetId']
    # Assign new Sony Ci ID of uploaded record to instace variable to delete in
    # `after` block.
    @sony_ci_asset_id = result['assetId']

    # Ingest a corresponding PBCore XML file with the just-uploaded Sony Ci ID
    ingester = PBCoreIngester.new
    ingester.ingest_xml_no_commit(pbcore_xml_with_sony_ci_id(@aapb_id, @sony_ci_asset_id))
    ingester.commit
    fetched_doc = Solr.instance.connect.get(:select, params: { q: "id:#{@aapb_id}" })['response']['docs'].first
    # Raise an error if the ingest didn't work.
    raise "Failed to ingest PBCore XML for #{@aapb_id}" unless fetched_doc
  end

  # Test cleanup - see comments for details on each cleanup action.
  after(:all) do
    # Delete record for @aapb_id set in `before` block.
    begin
      solr = Solr.instance.connect
      solr.delete_by_query("id:'#{@aapb_id}'")
    rescue StandardError => e
      Rails.logger.warn("Could not delete test record for #{@aapb_id} from Solr: #{e.message}\n#{e.backtrace}")
    end

    begin
      # Delete the uploaded test file from Sony Ci.
      sony_ci.delete("/assets/#{@sony_ci_asset_id}")
    rescue StandardError => e
      Rails.logger.warn "Failed to delete Sony Ci asset with ID #{@sony_ci_asset_id}: #{e.message}\n#{e.backtrace}"
    end

    # Undo the monkey patch to Exhibit.each by reloading exhibit.rb
    load 'app/models/exhibit.rb'
  end

  # Specify all referrers we want to test for allowing access to media
  AUTHORIZED_REFERRERS = %w(
    https://americanarchive.org
    https://iiif.aviaryplatform.com
    https://fake-avannotate-site.github.io
  ).freeze

  # Specify at least one unauthorized referrer, but add more if we need
  # to test restrictions for specific sites.
  UNAUTHORIZED_REFERRERS = %w(https://www.youtube.com).freeze

  # Test the /media/:id endpoint
  describe 'GET /media/:id' do
    let(:path) { "/media/#{@aapb_id}" }

    before(:all) do
      wait_time = 30
      puts "\n\nWaiting #{wait_time} seconds for streaming URL to get generated for new Sony Ci record..."
      sleep wait_time
      puts "continuing."
    end

    # Test authorized referrers for fetching the streaming URL.
    AUTHORIZED_REFERRERS.each do |referrer|
      context "when referrer is #{referrer}" do
        it 'Redirects to the Sony Ci streaming URL' do
          get path, nil, 'HTTP_REFERER' => referrer
          expect(response.status).to eq 302
          expect(response.location).to match(/https\:\/\/io\.cimediacloud\.com\/assets\/.*playlist\.m3u8/)
        end
      end
    end

    UNAUTHORIZED_REFERRERS.each do |referrer|
      context "when the referrer is #{referrer}" do
        it 'returns 401 unauthorized' do
          get path
          expect(response.status).to eq 401
        end
      end
    end

    context 'when there is no referrer' do
      it 'returns 401 unauthorized' do
        get "/media/#{@aapb_id}"
        expect(response.status).to eq 401
      end
    end
  end

  describe 'GET /media/:id/download' do
    let(:path) { "/media/#{@aapb_id}/download" }

    AUTHORIZED_REFERRERS.each do |referrer|
      context "when referer is #{referrer}" do
        it 'Redirects to the Sony Ci Asset Download URL' do
          get path, nil, 'HTTP_REFERER' => referrer
          expect(response.status).to eq 302
          expect(response.location).to match(/https\:\/\/cdn01\.cimediacloud\.com\/cifiles\/#{@sony_ci_asset_id}\/#{@aapb_id}\.mp4/)
        end
      end
    end

    UNAUTHORIZED_REFERRERS.each do |referrer|
      context "when the referrer is #{referrer}" do
        it 'returns 401 unauthorized' do
          get path, nil, 'HTTP_REFERER' => referrer
          expect(response.status).to eq 401
        end
      end
    end

    context 'when there is no referrer' do
      it 'returns 401 unauthorized' do
        get "/media/#{@aapb_id}/download"
        expect(response.status).to eq 401
      end
    end
  end
end

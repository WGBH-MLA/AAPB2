require 'aws-sdk'
require 'json'
require 'curl'
require 'rails_helper'

describe 'S3' do
  # For AAPB, all the S3 content is open, since the video delivery is managed by Ci.
  describe 'policy implementation', not_on_ci: true do
    def to_pretty_json(string_io)
      JSON.pretty_generate(JSON.parse(string_io.string))
    end

    let(:credentials) do
      # NOTE: config/aws.yml should be Git-ignored, so you will need to
      # create/get a valid set of for this test to succeed locally (is not
      # intended to be run in Github actions at this time).
      # A test IAM user and policy were created specifically for this purpose
      # Look in AWS IAM console for user aapb-s3-read-only and for attached
      # policy named aapb-s3-read-only-policy.
      credentials_hash = YAML.safe_load(File.read('config/aws.yml'))
      Aws::Credentials.new(credentials_hash['access_key_id'], credentials_hash['secret_access_key'])
    end

    let(:client) { Aws::S3::Client.new(region: 'us-east-1', credentials: credentials) }

    # Test to make sure the americanarchive.org (production) bucket has the expected policy.
    # TODO: move bucket policy config to a deployment repository, decouple from app code.
    it 'has expected policy' do
      expect(
        to_pretty_json(client.get_bucket_policy(bucket: 'americanarchive.org').policy)
      ).to eq(File.read(__dir__ + '/../fixtures/aws/bucket-policy.json'))
    end
  end

  # Ensure the current bucket policy allows us to access thumbnails.
  describe 'policy effect' do
    it 'allows thumbnail without referer' do
      curl = Curl::Easy.http_get('https://s3.amazonaws.com/americanarchive.org/thumbnail/cpb-aacip-41-644qrtnj.jpg')
      curl.perform
      expect(curl.status).to eq('200 OK')
    end
  end
end

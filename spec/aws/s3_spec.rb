require 'aws-sdk'
require 'json'
require 'curl'
require 'rails_helper'

describe 'S3' do
  # For AAPB, all the S3 content is open, since the video delivery is managed by Ci.
  describe 'policy implementation', not_on_travis: true do
    def to_pretty_json(string_io)
      JSON.pretty_generate(JSON.parse(string_io.string))
    end
    let(:client) { Aws::S3::Client.new(region: 'us-east-1') }
    it 'has expected policy' do
      expect(
        to_pretty_json(client.get_bucket_policy(bucket: 'americanarchive.org').policy)
      ).to eq(File.read(__dir__ + '/../fixtures/aws/bucket-policy.json'))
    end
  end
  describe 'policy effect' do
    it 'allows thumbnail without referer' do
      curl = Curl::Easy.http_get('https://s3.amazonaws.com/americanarchive.org/thumbnail/cpb-aacip-41-644qrtnj.jpg')
      curl.perform
      expect(curl.status).to eq('200 OK')
    end
  end
end

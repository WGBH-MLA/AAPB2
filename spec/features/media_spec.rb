require_relative '../../scripts/lib/pb_core_ingester'
require 'rails_helper'
require 'sony_ci_api'
require 'tmpdir'

describe 'Media URLs', not_on_travis: true do
  let(:file_content) { 'lorem ipsum' }

  def safe_ci
    credentials_path = Rails.root + 'config/ci.yml'
    ci = SonyCiAdmin.new(credentials_path: credentials_path)
    raise 'Workspace must be empty' unless ci.list_names.empty?
    ci
  end

  def setup(ci)
    Dir.mktmpdir do |dir|
      log_path = "#{dir}/log.txt"
      path = "#{dir}/small-file.txt"
      File.write(path, file_content)
      ci_id = ci.upload(path, log_path)

      pbcore = File.read('spec/fixtures/pbcore/clean-MOCK.xml')
      pbcore.gsub!('1234</pbcoreIdentifier>',
                   "1234</pbcoreIdentifier><pbcoreIdentifier source='Sony Ci'>#{ci_id}</pbcoreIdentifier>")

      ingester = PBCoreIngester.new
      ingester.delete_all
      ingester.ingest_xml_no_commit(pbcore)
      ingester.commit
      ci_id
    end
  end

  before do
    @ci = safe_ci
    @ci_id = setup(@ci)
  end

  after do
    @ci.delete(@ci_id)
  end

  def response_body_for_http_get(url, opts = {})
    curl = Curl::Easy.http_get(url)
    curl.headers['Referer'] = opts[:referer] if opts[:referer]
    curl.follow_location = true
    curl.perform
    curl.body_str
  end

  let(:media_url) { 'http://localhost:3000/media/1234' }

  context 'when referer is http://americanarchive.org' do
    it 'returns the media object from Sony Ci' do
      response_body = response_body_for_http_get(media_url, referer: 'http://americanarchive.org/')
      expect(response_body).to eq(file_content)
    end
  end

  # commenting this out since PopUp Archive is no longer in service
  # context 'when referer is http://popuparchive.com' do
  #   it 'returns the media object from Sony Ci' do
  #     response_body = response_body_for_http_get(media_url, referer: 'http://popuparchive.com/')
  #     expect(response_body).to eq(file_content)
  #   end
  # end
end

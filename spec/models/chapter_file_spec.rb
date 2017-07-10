require 'rails_helper'
require 'webmock'

describe ChapterFile do
  before :all do
    # WebMock is disabled by defafult, but we use it for these tests.
    # Note that it is re-disable in an :after hook below.
    WebMock.enable!
  end

  let(:id_1) { 'cpb-aacip_114-90dv49m9' }
  let(:id_2) { 'fake_id' }
  let(:vtt_example_1) { File.read('./spec/fixtures/chapters/cpb-aacip-114-90dv49m9.vtt') }

  before do
    # Stub requests so we don't actually have to fetch them remotely. But note
    # that this requires that the files have been pulled down and saved in
    # ./spec/fixtures/srt/ with the same filename they have in S3.
    WebMock.stub_request(:get, ChapterFile.vtt_url(id_1)).to_return(body: vtt_example_1)
    WebMock.stub_request(:get, ChapterFile.vtt_url(id_2)).to_return(status: 400, body: '', headers: {})
  end

  ###
  # Class method tests
  ###

  describe '.vtt_filename' do
    it 'returns the filename based on the ID' do
      expect(ChapterFile.vtt_filename(id_1)).to eq('cpb-aacip-114-90dv49m9.vtt')
    end
  end

  describe '.vtt_url' do
    it 'returns the URL to the remote SRT caption file' do
      expect(ChapterFile.vtt_url(id_1)).to eq 'https://s3.amazonaws.com/americanarchive.org/chapters/cpb-aacip-114-90dv49m9/cpb-aacip-114-90dv49m9.vtt'
    end
  end

  describe '.file_present?' do
    it 'returns true for an id with a file on S3' do
      expect(ChapterFile.file_present?(id_1)).to eq(true)
    end

    it 'returns false for an id without a file on S3' do
      expect(ChapterFile.file_present?(id_2)).to eq(false)
    end
  end

  after(:all) do
    # Re-disable WebMock so other tests can use actual connections.
    WebMock.disable!
  end
end

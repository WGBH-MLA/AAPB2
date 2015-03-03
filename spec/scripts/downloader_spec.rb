require 'tmpdir'
require_relative '../../scripts/lib/downloader'

describe Downloader, slow: true do
  it 'works' do
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do |dir|
        count_before = Dir.entries(dir).count
        days = 7 # There should be some new records in the past week.
        Downloader.new((Time.now - days * 24 * 60 * 60).strftime('%Y%m%d')).download_to_directory(1)
        count_after = Dir.entries(dir).count

        expect(count_before).to eq(2) # . and ..
        expect(count_after).to be > 2
      end
    end
  end

  describe 'bad dates' do
    it 'catches small' do
      expect { Downloader.new('20000000') }.to raise_error
    end
    it 'catches big' do
      expect { Downloader.new('20001332') }.to raise_error
    end
  end
end

require 'tmpdir'
require_relative '../../scripts/lib/downloader'

describe Downloader, not_on_travis: true do
  # Could be run on Travis, but very slow, and it depends on an outside service.
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

  describe 'download by id' do
    it 'works' do
      dir = Downloader.download_to_directory_and_link(ids: ['cpb-aacip/17-00000qrv'], is_same_mount: true)
      expect(dir).to match(/\d{4}-\d{2}-\d{2}.*_by_ids_1/)
      files = Dir["#{dir}/*.pbcore"]
      expect(files.map { |f| f.sub(/.*\//, '') }).to eq(['17-00000qrv.pbcore'])
      expect(File.read(files.first)).to match(/<pbcoreIdentifier source="http:\/\/americanarchiveinventory.org">cpb-aacip\/17-00000qrv/)
    end
  end
end

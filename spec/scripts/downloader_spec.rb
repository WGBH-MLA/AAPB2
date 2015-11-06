require 'tmpdir'
require_relative '../../scripts/lib/downloader'

describe Downloader do
  it 'can download the past 7 days', not_on_travis: true do
    # I really don't think it's a good idea to make the tests dependent
    # on the activity of the catalogers, though this is a good test otherwise.
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

  it 'downloads by id' do
    dir = Downloader.download_to_directory_and_link(ids: ['cpb-aacip/17-00000qrv'], is_same_mount: true)
    expect(dir).to match(/\d{4}-\d{2}-\d{2}.*_by_ids_1/)
    files = Dir["#{dir}/*.pbcore.zip"]
    expect(files.map { |f| f.sub(/.*\//, '') }).to eq(['17-00000qrv.pbcore.zip'])
    expect(Zipper.read(files.first)).to match(/<pbcoreIdentifier source="http:\/\/americanarchiveinventory.org">cpb-aacip\/17-00000qrv/)
  end
end

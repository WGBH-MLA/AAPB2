require 'tmpdir'
require_relative '../../scripts/lib/downloader'

describe Downloader do
  it 'can download the past 7 days', not_on_ci: true do
    # I really don't think it's a good idea to make the tests dependent
    # on the activity of the catalogers, though this is a good test otherwise.
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do |dir|
        count_before = Dir.entries(dir).count
        Downloader.new(days: 7).run # There should be some new records in the past week.
        count_after = Dir.entries(dir).count

        expect(count_before).to eq(2) # . and ..
        expect(count_after).to eq(2)
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

  it 'downloads by id', not_on_ci: true do
    dir = Downloader.new(ids: [0.chr + 'cpb-aacip/17-00000qrv' + 160.chr]).run
    # 0.chr and 160.chr to make sure we strip weird characters.
    expect(dir).to match(/\d{4}-\d{2}-\d{2}/)
    files = Dir["#{dir}/*.pbcore.zip"]
    expect(files.map { |f| f.sub(/.*\//, '') }).to eq(['17-00000qrv.pbcore.zip'])
    expect(Zipper.read(files.first)).to match(/<pbcoreIdentifier source="http:\/\/americanarchiveinventory.org">cpb-aacip\/17-00000qrv/)
  end
end

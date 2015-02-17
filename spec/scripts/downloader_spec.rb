require 'tmpdir'
require_relative '../../scripts/lib/downloader'

describe Downloader, slow: true do
  
  it 'works' do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do |dir|
        count_before = Dir.entries(dir).count
        Downloader.new((Time.now-7*24*60*60).strftime('%Y%m%d')).download_to_directory
        count_after = Dir.entries(dir).count

        expect(count_before).to eq(2) # . and ..
        expect(count_after).to be > 2
      end
    end
  end

end
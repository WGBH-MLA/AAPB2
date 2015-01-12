require_relative '../../scripts/downloader'

describe Downloader do
  
  it 'works for partial downloads' do
    downloader = Downloader.new(0, 0, 1)
    Dir.mktmpdir {|dir|
      count_before = Dir.entries(dir).count
      downloader.download_to_directory(dir)
      count_after = Dir.entries(dir).count
      
      expect(count_after).to eq(count_before + 1)
    }
  end
  
  it 'fails gently outside of window' do
    downloader = Downloader.new(0, 1000000, 1000001)
    Dir.mktmpdir {|dir|
      count_before = Dir.entries(dir).count
      downloader.download_to_directory(dir)
      count_after = Dir.entries(dir).count
      
      expect(count_after).to eq(count_before)
    }
  end

end
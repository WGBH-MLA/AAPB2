require_relative '../../scripts/download_clean_ingest'

describe DownloadCleanIngest do
  
  def capture
    begin
      old_stdout = $stdout
      old_stderr = $stderr
      $stdout = StringIO.new('','w')
      $stderr = StringIO.new('','w')
      yield
      $stdout.string + $stderr.string
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end
  end
  
  def dci_output(*args)
    capture { 
      begin
        DownloadCleanIngest.new(args).process()
      rescue SystemExit
        
      end
    }
  end
  
  describe 'docs' do
    it 'prints usage when no args' do
      expect(dci_output()).to match /logging to .*USAGE:/m
    end
#    it 'prints usage when not recognized' do
#      expect(dci_output('random', 'args', 'here')).to match /logging to .*USAGE:/
#    end
  end

end

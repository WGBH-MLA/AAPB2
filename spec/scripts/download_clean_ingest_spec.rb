require_relative '../../scripts/download_clean_ingest'

describe DownloadCleanIngest, not_on_travis: true do
  
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
      rescue SystemExit, RuntimeError => e
        $stderr.puts e.message
      end
    }
  end
  
  def describe_dci(args_string)
    describe args_string do
      let(:output) { dci_output(*args_string.split(/\s+/)) }
      yield
    end
  end

  {
    '' => [/USAGE:/],
    'random args here' => [/USAGE:/],
    '--stdout-log --ids fake-id' => [
      /logging to #</, /START: Process/, /add --same-mount to ignore/],
    '--stdout-log --same-mount --ids fake-id' => [
      /logging to #</, /START: Process/, /fake-id.pbcore: Neither pbcoreCollection nor pbcoreDocument/]
  }.each do |args, patterns|
    describe "download_clean_ingest.rb #{args}" do
      let(:output) { dci_output(*args.split(/\s+/)) }
      patterns.each do |pattern|
        it "matches /#{pattern.source}/" do
          expect(output).to match pattern
        end
      end
    end
  end

end

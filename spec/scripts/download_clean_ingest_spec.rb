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
      rescue SystemExit, RuntimeError => e
        $stderr.puts e.message
      end
    }
  end

  {
    # expect to fail:
    '' => [/USAGE:/],
    'random args here' => [/USAGE:/],
    '--stdout-log --ids fake-id' => [
      /logging to #</, /START: Process/, /add --same-mount to ignore/
    ],
    '--stdout-log --same-mount --ids fake-id' => [
      /logging to #</, /START: Process/, 
      /fake-id.pbcore: Neither pbcoreCollection nor pbcoreDocument/,
      /1 failed to validate/
    ],
    
    # expect to succeed:
    # (--back can be slow)
#    '--stdout-log --same-mount --back 1' => [
#      /Trying .*\/page\/1/,
#      /\d+ succeeded/
#    ],
    '--stdout-log --same-mount --ids 37-010p2nvv' => [
      /Downloading .*guid\/37-010p2nvv/,
      /Updated solr record cpb-aacip_37-010p2nvv/,
      /Successfully added .*37-010p2nvv.pbcore/,
      /1 succeeded/
    ],
    "--stdout-log --same-mount --id-files #{File.dirname(__FILE__)}/../fixtures/id-files/id-file.txt" => [
      /Downloading .*guid\/37-010p2nvv/,
      /Updated solr record cpb-aacip_37-010p2nvv/,
      /Successfully added .*37-010p2nvv.pbcore/,
      /1 succeeded/],
    '--stdout-log --same-mount --dirs XXX' => [],
    '--stdout-log --same-mount --files XXX' => []
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

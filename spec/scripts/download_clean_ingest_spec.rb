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

  default_flags = '--stdout-log --same-mount --skip-sitemap'
  default_mode = "--files #{File.dirname(__FILE__)}/../fixtures/dci/pbcore-dir/pbcore.xml"
  {
    # Expected to fail:
    '' => [/USAGE:/],
    'random args here' => [/USAGE:/],
    '--stdout-log --ids fake-id' => [/add --same-mount to ignore/],
    "#{default_flags} --ids fake-id" => [
      /fake-id.pbcore: Neither pbcoreCollection nor pbcoreDocument/,
      /1 failed to validate/
    ],
    "--just-reindex #{default_flags} #{default_mode}" => [
      /should only be used with ID modes/,
    ],
    
    # Modes expected to succeed:
    # (--back can be slow)
#    '--stdout-log --same-mount --back 1' => [
#      /Trying .*\/page\/1/,
#      /\d+ succeeded/
#    ],
    "#{default_flags} --ids 37-010p2nvv" => [
      /Downloading .*guid\/37-010p2nvv/,
      /Updated solr record cpb-aacip_37-010p2nvv/,
      /Successfully added .*37-010p2nvv.pbcore/,
      /1 succeeded/
    ],
    "#{default_flags} --id-files #{File.dirname(__FILE__)}/../fixtures/dci/id-file.txt" => [
      /Downloading .*guid\/37-010p2nvv/,
      /Updated solr record cpb-aacip_37-010p2nvv/,
      /Successfully added .*37-010p2nvv.pbcore/,
      /1 succeeded/
    ],
    "#{default_flags} --dirs #{File.dirname(__FILE__)}/../fixtures/dci/pbcore-dir" => [
      /Updated solr record 1234/,
      /1 succeeded/
    ],
    "#{default_flags} --files #{File.dirname(__FILE__)}/../fixtures/dci/pbcore-dir/pbcore.xml" => [
      /Updated solr record 1234/,
      /1 succeeded/
    ],
    
    # Flags expected to succeed:
    "--batch-commit #{default_flags} #{default_mode}" => [
      /Updated solr record 1234/,
      /Starting one big commit/,
      /1 succeeded/
    ],
    "--just-reindex #{default_flags} --ids 1234" => [
      # XXX: order dependent! Depends on an earlier test to have loaded the data.
      /Query solr for 1234/,
      /Updated solr record 1234/,
      /1 succeeded/
    ],
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

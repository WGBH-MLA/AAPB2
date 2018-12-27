require_relative '../../scripts/download_clean_ingest'

describe DownloadCleanIngest do
  def capture
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new('', 'w')
    $stderr = StringIO.new('', 'w')
    yield
    $stdout.string + $stderr.string
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end

  def dci_output(*args)
    capture do
      begin
        DownloadCleanIngest.new(args).process
      rescue SystemExit, RuntimeError => e
        $stderr.puts e.inspect, e.backtrace.join("\n")
      end
    end
  end

  default_flags = '--stdout-log'
  default_mode = "--files #{Rails.root + 'spec/fixtures/dci/pbcore-dir/pbcore.xml'}"
  {
    # Expected to fail:
    '' => [
      /USAGE:/
    ],
    'random args here' => [
      /USAGE:/
    ],
    "#{default_flags} --files /this/path/is/no/good" => [
      /1 \(100.0%\) Errno::ENOENT/
    ],
    "#{default_flags} --ids fake-id" => [
      /fake-id.pbcore.zip : Neither pbcoreCollection nor pbcoreDocument/,
      /1 \(100.0%\) PBCoreIngester::ValidationError/
    ],
    "--just-reindex #{default_flags} #{default_mode}" => [
      /should only be used with/
    ],
    "#{default_mode} #{default_flags} --this-is-not-valid -neither-is-this" => [
      /Unrecognized flags: --this-is-not-valid, -neither-is-this/
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
      /Processed .*37-010p2nvv.pbcore/,
      /1 \(100.0%\) succeeded/
    ],
    "#{default_flags} --id-files #{Rails.root + 'spec/fixtures/dci/id-file.txt'}" => [
      /Downloading .*guid\/37-010p2nvv/,
      /Updated solr record cpb-aacip_37-010p2nvv/,
      /Processed .*37-010p2nvv.pbcore/,
      /1 \(100.0%\) succeeded/
    ],
    "#{default_flags} --dirs #{Rails.root + 'spec/fixtures/dci/pbcore-dir'}" => [
      /Updated solr record 1234/,
      /1 \(100.0%\) succeeded/
    ],
    "#{default_flags} --files #{Rails.root + 'spec/fixtures/dci/pbcore-dir/pbcore.xml'}" => [
      /Updated solr record 1234/,
      /1 \(100.0%\) succeeded/
    ],
    "#{default_flags} --exhibits historic-preservation/marginalized-perspectives" => [
      # Choose the smallest exhibit we have, since the test will be hitting the AMS.
      # Perhaps it should be skipped?
      /Updated solr record cpb-aacip_80-87pnwmp2/,
      /\d+ \(100.0%\) succeeded/
    ],
    "#{default_flags} --just-reindex --query 'f[asset_type][]=Program&q=promise'" => [
      /Query solr for/,
      /Updated solr record cpb-aacip_221-76f1vwh1/,
      /Processed .*221-76f1vwh1.pbcore/,
      /Updated solr record cpb-aacip_37-010p2nvv/,
      /Processed .*37-010p2nvv.pbcore/,
      /13 \(100.0%\) succeeded/
    ],

    # Flags expected to succeed:
    "--batch-commit #{default_flags} #{default_mode}" => [
      /Updated solr record 1234/,
      /Starting one big commit/,
      /1 \(100.0%\) succeeded/
    ],
    "--just-reindex #{default_flags} --ids 1234" => [
      # XXX: order dependent! Depends on an earlier test to have loaded the data.
      /Query solr for 1234/,
      /Updated solr record 1234/,
      /1 \(100.0%\) succeeded/
    ]
  }.each do |args, patterns|
    describe "download_clean_ingest.rb #{args}" do
      let(:output) do
        dci_output(*args.split(/\s+/).map do |arg|
          arg.sub(/(^['"])|(['"]$)/, '')
          # There might be quotes around args if pasted from commandline.
        end) end
      patterns.each do |pattern|
        it "matches /#{pattern.source}/" do
          expect(output).to match pattern
        end
      end
    end
  end
end

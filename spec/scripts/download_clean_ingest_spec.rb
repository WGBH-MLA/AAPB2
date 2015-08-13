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
    capture {
      begin
        DownloadCleanIngest.new(args).process
      rescue SystemExit, RuntimeError => e
        $stderr.puts e.inspect, e.backtrace.join("\n")
      end
    }
  end

  default_flags = '--stdout-log --same-mount --skip-sitemap'
  default_mode = "--files #{Rails.root + 'spec/fixtures/dci/pbcore-dir/pbcore.xml'}"
  {
    # Expected to fail:
    '' => [
      /USAGE:/
    ],
    'random args here' => [
      /USAGE:/
    ],
    '--stdout-log --ids fake-id' => [
      /add --same-mount to ignore/
    ],
    "#{default_flags} --files /this/path/is/no/good" => [
      /1 Errno::ENOENT errors \(100%\)/
    ],
    "#{default_flags} --ids fake-id" => [
      /fake-id.pbcore : Neither pbcoreCollection nor pbcoreDocument/,
      /1 PBCoreIngester::ValidationError errors \(100%\)/
    ],
    "--just-reindex #{default_flags} #{default_mode}" => [
      /should only be used with/
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
      /1 \(100%\) succeeded/
    ],
    "#{default_flags} --id-files #{Rails.root + 'spec/fixtures/dci/id-file.txt'}" => [
      /Downloading .*guid\/37-010p2nvv/,
      /Updated solr record cpb-aacip_37-010p2nvv/,
      /Processed .*37-010p2nvv.pbcore/,
      /1 \(100%\) succeeded/
    ],
    "#{default_flags} --dirs #{Rails.root + 'spec/fixtures/dci/pbcore-dir'}" => [
      /Updated solr record 1234/,
      /1 \(100%\) succeeded/
    ],
    "#{default_flags} --files #{Rails.root + 'spec/fixtures/dci/pbcore-dir/pbcore.xml'}" => [
      /Updated solr record 1234/,
      /1 \(100%\) succeeded/
    ],
    "#{default_flags} --exhibits midwest" => [
      /Updated solr record/,
      /succeeded/ # TODO: Enrich this when we have solid examples that won't be breaking.
    ],
    "#{default_flags} --just-reindex --query 'f[asset_type][]=Episode&q=promise'" => [
      /Query solr for/,
      /Updated solr record cpb-aacip_37-010p2nvv/,
      /Processed .*37-010p2nvv.pbcore/,
      /1 \(100%\) succeeded/
    ],

    # Flags expected to succeed:
    "--batch-commit #{default_flags} #{default_mode}" => [
      /Updated solr record 1234/,
      /Starting one big commit/,
      /1 \(100%\) succeeded/
    ],
    "--just-reindex #{default_flags} --ids 1234" => [
      # XXX: order dependent! Depends on an earlier test to have loaded the data.
      /Query solr for 1234/,
      /Updated solr record 1234/,
      /1 \(100%\) succeeded/
    ]
  }.each do |args, patterns|
    describe "download_clean_ingest.rb #{args}" do
      let(:output) {
        dci_output(*args.split(/\s+/).map {|arg|
          arg.sub(/(^['"])|(['"]$)/, '')
            # There might be quotes around args if pasted from commandline.
        }) }
      patterns.each do |pattern|
        it "matches /#{pattern.source}/" do
          expect(output).to match pattern
        end
      end
    end
  end
end

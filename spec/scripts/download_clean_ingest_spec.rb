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
    "#{default_mode} #{default_flags} --this-is-not-valid -neither-is-this" => [
      /Unrecognized flags: --this-is-not-valid, -neither-is-this/
    ],

    "#{default_flags} --dirs #{Rails.root + 'spec/fixtures/dci/pbcore-dir'}" => [
      /Updated solr record 1234/,
      /1 \(100.0%\) succeeded/
    ],
    "#{default_flags} --files #{Rails.root + 'spec/fixtures/dci/pbcore-dir/pbcore.xml'}" => [
      /Updated solr record 1234/,
      /1 \(100.0%\) succeeded/
    ],

    # Flags expected to succeed:
    "--batch-commit #{default_flags} #{default_mode}" => [
      /Updated solr record 1234/,
      /Starting one big commit/,
      /1 \(100.0%\) succeeded/
    ]
  }.each do |args, expeected_output_patterns|
    describe "download_clean_ingest.rb #{args}" do
      let(:output) do
        dci_output(*args.split(/\s+/).map do |arg|
          arg.sub(/(^['"])|(['"]$)/, '')
          # There might be quotes around args if pasted from commandline.
        end) end
      expeected_output_patterns.each do |expeected_output_pattern|
        it "matches /#{expeected_output_pattern.source}/" do
          expect(output).to match expeected_output_pattern
        end
      end
    end
  end
end

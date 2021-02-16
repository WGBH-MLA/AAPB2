require 'optparse'
require_relative '../transcript_downloader'

task :download_transcripts do
  options = {}
  parser = OptionParser.new
  parser.banner = "Usage: rake download_transcripts -- --contrib=\"organization name\""
  parser.on("-c", "--contrib=CONTRIB", String, "[REQUIRED] Specify a contributing organization") do |c|
    options[:c] = c
  end
  args = parser.order!(ARGV) {} #=> this line is required, return `ARGV` with the intended arguments
  parser.parse!(args)

  TranscriptDownloader.new(contrib: options[:c]).download
end

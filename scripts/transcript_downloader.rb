require_relative 'lib/null_logger'
require_relative '../lib/solr'
require_relative '../app/models/pb_core_presenter'
require 'optparse'
require 'open-uri'
require 'zip'

class TranscriptDownloader

  attr_reader :contributing_organization, :solr_docs, :dir

  def initialize(contributing_organization:nil, dir:nil)
    raise 'contributing_organization cannot be nil' if contributing_organization.nil?
    @contributing_organization = contributing_organization
    @dir = dir.nil? ? 'tmp/downloads/transcripts' : dir
    @solr_docs = Solr.instance.connect.get('select', params: { q: "contributing_organizations:\"#{contributing_organization}\"" })['response']['docs']
    $LOG ||= NullLogger.new
  end

  def download
    transcript_files = download_transcripts
    zip_transcript_files(transcript_files)
  end

  private

  def download_transcripts
    files = {}
    solr_docs.each do |doc|
      $LOG.info("Checking transcript_src for: " + doc["id"].to_s)
      transcript_src = PBCorePresenter.new(doc["xml"]).transcript_src

      unless transcript_src.nil?
        $LOG.info("Downloading transcript for: " + doc["id"].to_s)
        files[doc["id"]] = open(transcript_src)
      end
    end
    files
  end

  def mkdir
    path = Rails.root + dir
    FileUtils.mkdir_p(path)
  end


  def zip_transcript_files(files)
    friendly_org_name = contributing_organization.gsub(/[[:punct:]]/, "").split(' ').join('-')

    zipfile_name = mkdir.first + '/' + Time.now.iso8601 + friendly_org_name + '-transcripts' + ".zip"
    $LOG.info("Writing all transcripts to: " + zipfile_name.to_s)

    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      files.map { |id,file| zipfile.add(id.to_s + "-transcript.json", file) }
    end
  end
end

# options = {}
# OptionParser.new do |opts|
#   opts.banner = "Usage: example.rb [options]"
#   opts.on("-contrib", "--contributing_organization", "Download Transcripts by Contributing Organization") do |c|
#     options[:contributing_organization] = c
#   end
# end.parse!

# TranscriptDownloader.new(options).download
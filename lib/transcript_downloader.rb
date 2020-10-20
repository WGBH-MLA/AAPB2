require_relative './rails_stub'
require_relative '../app/models/exhibit'
require_relative './solr'
require_relative '../app/models/pb_core_presenter'
require_relative '../app/models/exhibit'
require 'optparse'
require 'open-uri'
require 'zip'

class TranscriptDownloader
  attr_reader :contrib, :solr_docs, :dir

  def initialize(contrib:nil, dir:nil)
    raise 'contrib cannot be nil' if contrib.nil?
    @contrib = contrib
    @dir = dir.nil? ? 'tmp/downloads/transcripts' : dir
    @solr_docs = Solr.instance.connect.get('select', params: { q: "contributing_organizations:\"#{contrib}\"" })['response']['docs']
    puts "START: TranscriptDownloader Process ##{Process.pid}"
  end

  def download
    transcript_files = download_transcripts
    zip_transcript_files(transcript_files)
  end

  private

  def download_transcripts
    files = {}
    solr_docs.each do |doc|
      puts "Checking transcript_src for: " + doc["id"].to_s
      transcript_src = PBCorePresenter.new(doc["xml"]).transcript_src

      unless transcript_src.nil?
        puts "Downloading transcript for: " + doc["id"].to_s
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
    friendly_org_name = contrib.gsub(/[[:punct:]]/, "").split(' ').join('-')

    zipfile_name = mkdir.first + '/' + Time.now.iso8601 + friendly_org_name + '-transcripts' + ".zip"
    puts "Writing all transcripts to: " + zipfile_name.to_s

    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      files.map { |id, file| zipfile.add(id.to_s + "-transcript.json", file) }
    end
  end
end

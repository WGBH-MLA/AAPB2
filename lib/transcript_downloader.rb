require_relative './rails_stub'
require_relative '../app/models/exhibit'
require_relative './solr'
require_relative '../app/models/pb_core_presenter'
require_relative '../app/models/exhibit'
require 'optparse'
require 'open-uri'
require 'zip'

class TranscriptDownloader
  attr_reader :contrib, :solr_docs, :zip_dir

  def initialize(contrib: nil)
    raise 'contrib cannot be nil' if contrib.nil?
    @contrib = contrib
    @zip_dir = mkdir.first
    @solr_docs = Solr.instance.connect.get('select', params: { q: "contributing_organizations:\"#{contrib}\"", rows: 99_999 })['response']['docs']
    puts "START: TranscriptDownloader Process ##{Process.pid}"
  end

  def download
    download_transcripts
    zip_transcript_files
    cleanup_download_dir
  end

  private

  def download_transcripts
    files = {}
    solr_docs.each do |doc|
      puts "Checking transcript_src for: " + doc["id"].to_s
      transcript_src = PBCorePresenter.new(doc["xml"]).transcript_src

      unless transcript_src.nil?
        puts "Downloading transcript for: " + doc["id"].to_s
        download_transcript(transcript_src, zip_dir + '/' + doc["id"].to_s + '.json')
      end
    end
    files
  end

  def download_transcript(url, dest)
    open(url) do |u|
      File.open(dest, 'wb') { |f| f.write(u.read) }
    end
  end

  def mkdir
    friendly_org_name = contrib.gsub(/[[:punct:]]/, "").split(' ').join('-')
    path = Rails.root + 'tmp/downloads/transcripts' + (Time.now.iso8601.to_s + '-' + friendly_org_name)
    FileUtils.mkdir_p(path)
  end

  def zip_transcript_files
    ZipFileGenerator.new(zip_dir, zip_dir + '.zip').write
  end

  def cleanup_download_dir
    FileUtils.rm_rf(zip_dir)
  end
end

class ZipFileGenerator
  # Taken almost verbatem from the the rubyzip docs.
  # Initialize with the directory to zip and the location of the output archive.
  def initialize(input_dir, output_file)
    @input_dir = input_dir
    @output_file = output_file
  end

  def write
    entries = Dir.entries(@input_dir) - %w(. ..)

    ::Zip::File.open(@output_file, ::Zip::File::CREATE) do |zipfile|
      write_entries entries, '', zipfile
    end
  end

  private

  def write_entries(entries, path, zipfile)
    entries.each do |e|
      zipfile_path = path == '' ? e : File.join(path, e)
      disk_file_path = File.join(@input_dir, zipfile_path)

      put_into_archive(disk_file_path, zipfile, zipfile_path)
    end
  end

  def put_into_archive(disk_file_path, zipfile, zipfile_path)
    zipfile.add(zipfile_path, disk_file_path)
  end
end

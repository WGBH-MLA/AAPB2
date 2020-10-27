require_relative './rails_stub'
require_relative '../app/models/exhibit'
require_relative './solr'
require_relative '../app/models/pb_core_presenter'
require_relative '../app/models/exhibit'
require 'optparse'
require 'open-uri'
require 'zip'

class TranscriptDownloader
  attr_reader :contrib, :solr_docs, :dir, :zip_dir

  def initialize(contrib:nil, dir:nil)
    raise 'contrib cannot be nil' if contrib.nil?
    @contrib = contrib
    @dir = dir.nil? ? 'tmp/downloads/transcripts' : dir
    @zip_dir = mkdir.first
    @solr_docs = Solr.instance.connect.get('select', params: { q: "contributing_organizations:\"#{contrib}\"" })['response']['docs']
    puts "START: TranscriptDownloader Process ##{Process.pid}"
  end

  def download
    transcript_files = download_transcripts
    zip_transcript_files
  end

  private

  def download_transcripts
    files = {}
    solr_docs.each do |doc|
      puts "Checking transcript_src for: " + doc["id"].to_s
      transcript_src = PBCorePresenter.new(doc["xml"]).transcript_src

      unless transcript_src.nil?
        puts "Downloading transcript for: " + doc["id"].to_s
        download_transcript(transcript_src, zip_dir + '/' + doc["id"].to_s + '.json' )
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
    path = Rails.root + dir + "#{Time.now.iso8601 + '-' +friendly_org_name}"
    FileUtils.mkdir_p(path)
  end

  # def zip_transcript_files(files)
  #   friendly_org_name = contrib.gsub(/[[:punct:]]/, "").split(' ').join('-')

  #   zipfile_name = mkdir.first + '/' + Time.now.iso8601 + friendly_org_name + '-transcripts' + ".zip"
  #   puts "Writing all transcripts to: " + zipfile_name.to_s

  #   Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
  #     files.map { |id, file| zipfile.add(id.to_s + "-transcript.json", file) }
  #   end
  # end

  def zip_transcript_files
    ZipFileGenerator.new(zip_dir, zip_dir + '.zip').write
  end
end

class ZipFileGenerator
  # Initialize with the directory to zip and the location of the output archive.
  def initialize(input_dir, output_file)
    @input_dir = input_dir
    @output_file = output_file
  end

  # Zip the input directory.
  def write
    entries = Dir.entries(@input_dir) - %w[. ..]

    ::Zip::File.open(@output_file, ::Zip::File::CREATE) do |zipfile|
      write_entries entries, '', zipfile
    end
  end

  private

  # A helper method to make the recursion work.
  def write_entries(entries, path, zipfile)
    entries.each do |e|
      zipfile_path = path == '' ? e : File.join(path, e)
      disk_file_path = File.join(@input_dir, zipfile_path)

      if File.directory? disk_file_path
        recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
      else
        put_into_archive(disk_file_path, zipfile, zipfile_path)
      end
    end
  end

  def recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
    zipfile.mkdir zipfile_path
    subdir = Dir.entries(disk_file_path) - %w[. ..]
    write_entries subdir, zipfile_path, zipfile
  end

  def put_into_archive(disk_file_path, zipfile, zipfile_path)
    zipfile.add(zipfile_path, disk_file_path)
  end
end

require_relative '../lib/solr'
require_relative '../app/helpers/solr_guid_fetcher'
require_relative 'lib/downloader'
require_relative 'download_clean_ingest'
require 'rsolr'
require 'logger'

class ThePBCoreCorrector
  TITLE_TYPES = ['series', 'program', 'episode', 'episode number', 'segment', 'clip', 'promo', 'raw footage'].freeze
  DESCRIPTION_TYPES = ['series', 'program', 'episode', 'segment', 'clip', 'promo', 'raw footage'].freeze

  def initialize(guids)
    log_init
    # Download the existing docs
    @target_dirs = download(ids: guids)
  end

  def run
    unzip_files
    edit_files
    reindex_files
  end

  private

  def log_init
    log_file_name = Rails.root + "log/#{Time.now.strftime('%F_%T.%6N')}-pbcorecorrector.log"
    $LOG = Logger.new(log_file_name, 'daily')
    $LOG.formatter = proc do |severity, datetime, _progname, msg|
      "#{severity} [#{datetime.strftime('%Y-%m-%d %H:%M:%S')}]: #{msg}\n"
    end
    puts "logging to #{log_file_name}"
    $LOG.info("START: PBCoreCorrector Process ##{Process.pid}")
  end

  # Unzip the files from the Downloader
  def unzip_files
    completed_files = []
    Dir.foreach(@target_dirs[0]) do |file_name|
      if file_name.include?(".zip") && !completed_files.include?(file_name)
        system("unzip", file_name)
        completed_files << file_name
      end
    end
    # Delete the zip files
    Dir.glob(@target_dirs[0] + "/*").select { |file| /\S+(.zip)/.match file }.each { |file| File.delete(file) }
  end

  def edit_files
    # Edit the PBCore files that came from AMS2
    Dir.glob(@target_dirs[0] + '/*') do |file|
      $LOG.info("CHECKING PBCORE FILE: #{file}")

      # Removing namespaces for easier parsing.
      doc = Nokogiri::XML(File.open(file)).remove_namespaces!

      # Edit Title and Desc elements
      titles = doc.xpath("//pbcoreTitle")
      descriptions = doc.xpath("//pbcoreDescription")

      # Skip rewrite if there's absolutely nothing to rewrite with
      if titles.map { |title| title["source"] }.uniq == [nil] && descriptions.map { |desc| desc["source"] }.uniq == [nil]
        $LOG.info("NO TITLES OR DESCRIPTIONS TO EDIT\nSKIPPING AND DELETING PBCORE FILE: #{file}")
        File.delete(file)
        next
      end

      titles.each do |title|
        # Skip if particular title source is nil
        next if title["source"].nil?
        $LOG.info("EDITING TITLE_TYPE #{title['source']} FOR PBCORE FILE: #{file}")
        title["titleType"] = title["source"] if TITLE_TYPES.include?(title["source"].downcase)
      end

      descriptions.each do |desc|
        # Skip if particular desc source is nil
        next if desc["source"].nil?
        $LOG.info("EDITING DESCRIPTION_TYPE #{desc['source']} FOR PBCORE FILE: #{file}")
        desc["descriptionType"] = desc["source"] if DESCRIPTION_TYPES.include?(desc["source"].downcase)
      end

      # Re-adding namespaces to pass validation
      doc.xpath("//pbcoreDescriptionDocument").first.add_namespace(nil, "http://www.pbcore.org/PBCore/PBCoreNamespace.html")
      doc.xpath('//xmlns:pbcoreDescriptionDocument').first.add_namespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
      doc.xpath("//xmlns:pbcoreDescriptionDocument").first.attributes["schemaLocation"].name = "xsi:schemaLocation"

      # Overwrite existing .pbcore file
      File.open(file, "w") do |f|
        f.write doc.to_xml
        f.close
      end

      $LOG.info("FINISHED EDITING PBCORE FILE: #{file}")
    end
  end

  def reindex_files
    if Dir.glob(@target_dirs[0] + '/*').empty?
      $LOG.info("NO FILES EDITED, SKIPPING REINDEX")
      return
    end
    # Reindex the files
    $LOG.info("REINDEXING NEW FILES WITH DownloadCleanIngest SCRIPT")
    DownloadCleanIngest.new(['--dirs', @target_dirs[0]]).process
  end

  def download(opts)
    $LOG.info("DOWNLOADING GUIDS")
    [Downloader.new(
      # Setting is_just_reindex to true gets the record from AAPB SOLR
      { is_just_reindex: true }.merge(opts)
    ).run]
  end
end

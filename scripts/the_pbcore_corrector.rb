require_relative '../lib/solr'
require_relative '../app/helpers/solr_guid_fetcher'
require_relative 'lib/pb_core_ingester'
require_relative 'lib/downloader'
require 'rsolr'


class ThePBCoreCorrector

  TITLE_TYPES = [ 'series', 'program', 'episode', 'episode number', 'segment', 'clip', 'promo', 'raw footage' ]
  DESCRIPTION_TYPES = [ 'series', 'program', 'episode', 'segment', 'clip', 'promo', 'raw footage' ]

  def initialize(guids)
    # Download the existing docs
    target_dirs = download(ids: guids)

    @files ||= target_dirs.map do |target_dir|
      Dir.entries(target_dir)
         .reject { |file_name| ['.', '..'].include?(file_name) }
         .map { |file_name| "#{target_dir}/#{file_name}" }
    end.flatten.sort

    # Unzip the files from the Downloader
    completed_files = Array.new
    Dir.foreach(target_dirs[0]) do |file_name|
      if (file_name.include?(".zip") && !completed_files.include?(file_name))
        system("unzip", file_name)
        completed_files << file_name
      end
    end
    # Delete the zip files
    Dir.glob(target_dirs[0] + "/*").select{ |file| /\S+(.zip)/.match file }.each { |file| File.delete(file)}

    # Edit the PBCore files that came from AMS2
    Dir.glob(target_dirs[0] + '/*' ) do |file|
      doc = Nokogiri.XML(File.open(file)).remove_namespaces!

      # Edit Title elements
      titles = doc.xpath("//pbcoreTitle")
      titles.each do |title|
        title["titleType"] = title["source"] if TITLE_TYPES.include?(title["source"].downcase)
      end

      # Edit Description elements
      descriptions = doc.xpath("//pbcoreDescription")
      descriptions.each do |desc|
        desc["descriptionType"] = desc["source"] if DESCRIPTION_TYPES.include?(desc["source"].downcase)
      end

      # Overwrite existing .pbcore file
    end


    # Reindex the files

  end

  def download(opts)
    [Downloader.new(
      # Setting is_just_reindex to true gets the record from AAPB SOLR
      { is_just_reindex: true }.merge(opts)
    ).run]
  end



end
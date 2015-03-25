require_relative 'lib/downloader'
require_relative 'lib/cleaner'
require_relative 'lib/pb_core_ingester'

if __FILE__ == $PROGRAM_NAME

  $stdout.sync # TODO: Use a real logging framework

  class Exception
    def short
      message + "\n" + backtrace[0..2].join("\n")
    end
  end

  class ParamsError < StandardError
  end

  class String
    def colorize(color_code)
      "\e[#{color_code}m#{self}\e[0m"
    end

    def red
      colorize(31)
    end

    def green
      colorize(32)
    end
  end

  fails = { read: [], clean: [], validate: [], add: [], other: [] }
  success = []

  ingester = PBCoreIngester.new  

  ONE_COMMIT = '--one-commit'
  ALL = '--all'
  BACK = '--back'
  DIRS = '--dirs'
  FILES = '--files'
  IDS = '--ids'
  
  one_commit = ARGV.include?(ONE_COMMIT)
  ARGV.delete(ONE_COMMIT) if one_commit
  
  mode = ARGV.shift
  args = ARGV

  begin
    case mode

    when ALL
      fail ParamsError.new unless args.count < 2 && (!args.first || args.first.to_i > 0)
      target_dirs = [Downloader.download_to_directory_and_link(page: args.first.to_i)]

    when BACK
      fail ParamsError.new unless args.count == 1 && args.first.to_i > 0
      target_dirs = [Downloader.download_to_directory_and_link(days: args.first.to_i)]

    when DIRS
      fail ParamsError.new if args.empty? || not(args.map {|dir| File.directory?(dir)}.all?) 
      target_dirs = args

    when FILES
      fail ParamsError.new if args.empty?
      files = args
      
    when IDS
      fail ParamsError.new unless args.count >= 1
      target_dirs = [Downloader.download_to_directory_and_link(ids: args)]

    else
      fail ParamsError.new
    end
  rescue ParamsError
    abort "USAGE: [#{ONE_COMMIT}] #{ALL} [PAGE] | #{BACK} DAYS | #{DIRS} DIR ... | #{FILES} FILE ... | #{IDS} ID ..."
  end

  files ||= target_dirs.map do |target_dir|
    Dir.entries(target_dir)
            .reject { |file_name| ['.', '..'].include?(file_name) }
            .map { |file_name| "#{target_dir}/#{file_name}" }
  end.flatten

  files.each do |path|
    begin
      ingester.ingest(path: path, one_commit: one_commit)
    rescue PBCoreIngester::ReadError => e
      puts "Failed to read #{path}: #{e.short}".red
      fails[:read] << path
      next
    rescue PBCoreIngester::ValidationError => e
      puts "Failed to validate #{path}: #{e.short}".red
      fails[:validate] << path
      next
    rescue PBCoreIngester::SolrError => e
      puts "Failed to add #{path}: #{e.short}".red
      fails[:add] << path
      next
    rescue => e
      puts "Other error on #{path}: #{e.short}".red
      fails[:other] << path
      next
    else
      puts "Successfully added '#{path}'".green
      success << path
    end
  end
  
  ingester.commit if one_commit

  # TODO: Investigate whether optimization is worth it. Requires a lot of disk and time.
  # puts 'Ingest complete; Begin optimization...'
  # ingester.optimize

  puts 'SUMMARY'

  puts "processed #{target_dirs}" if target_dirs
  fails.each {|type, list|
    puts "#{list.count} failed to #{type}:\n#{list.join("\n")}".red unless list.empty?
  }
  puts "#{success.count} succeeded".green

  puts 'DONE'
end

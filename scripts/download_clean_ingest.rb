require_relative 'lib/downloader'
require_relative 'lib/cleaner'
require_relative 'lib/pb_core_ingester'

if __FILE__ == $PROGRAM_NAME

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

  mode = ARGV.shift
  args = ARGV

  begin
    case mode

    when '--all'
      fail ParamsError.new unless args.count < 2 && (!args.first || args.first.to_i > 0)
      target_dir = Downloader.download_to_directory_and_link(page: args.first.to_i)

    when '--back'
      fail ParamsError.new unless args.count == 1 && args.first.to_i > 0
      target_dir = Downloader.download_to_directory_and_link(days: args.first.to_i)

    when '--dir'
      fail ParamsError.new unless args.count == 1 && File.directory?(args.first)
      target_dir = args.first

    when '--files'
      fail ParamsError.new if args.empty?
      files = args

    else
      fail ParamsError.new
    end
  rescue ParamsError
    abort 'USAGE: --all [PAGE] | --back DAYS | --dir DIR | --files FILE ...'
  end

  files ||= Dir.entries(target_dir)
            .reject { |file_name| ['.', '..'].include?(file_name) }
            .map { |file_name| "#{target_dir}/#{file_name}" }

  files.each do |path|
    begin
      ingester.ingest(path)
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

  puts 'SUMMARY'

  puts "processed #{target_dir}" if target_dir
  fails.each {|type, list|
    puts "#{list.count} failed to #{type}:\n#{list.join("\n")}".red unless list.empty?
  }
  puts "#{success.count} succeeded".green

  puts 'DONE'
end

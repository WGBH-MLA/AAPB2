require_relative 'lib/downloader'
require_relative 'lib/uncollector'
require_relative 'lib/cleaner'
require_relative 'lib/pb_core_ingester'

if __FILE__ == $0
  
  class Exception
    def short
      self.message + "\n" + self.backtrace[0..2].join("\n")
    end
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
  
  fails = {read: [], clean: [], validate: [], add: [], other: []}
  success = []
  
  cleaner = Cleaner.new
  ingester = PBCoreIngester.new
  
  mode = ARGV.shift
  args = ARGV
  
  begin
    case mode
      
    when '--all'
      raise ArgumentError.new unless args.empty?
      target_dir = Downloader::download_to_directory_and_link()
      
    when '--back'
      raise ArgumentError.new unless args.count == 1 && args.first.to_i > 0
      target_dir = Downloader::download_to_directory_and_link(args.first.to_i)
      
    when '--dir'
      raise ArgumentError.new unless args.count == 1 && File.directory?(args.first)
      target_dir = args.first
      
    when '--files'
      raise ArgumentError.new if args.empty?
      files = args
      
    else
      raise ArgumentError.new
    end
  rescue ArgumentError
    abort "USAGE: --all | --back N | --dir DIR | --files FILE ..."
  end
  
  files ||= Dir.entries(target_dir)
    .reject{|file_name| ['.','..'].include?(file_name)}
    .map{|file_name| "#{target_dir}/#{file_name}"}
    
  files.each do |path|
    
    begin
      dirty_xml = File.read(path)
    rescue => e
      puts "Failed to read #{path}: #{e.short}".red
      fails[:read] << path
      next
    end
    
    begin
      clean_xml = cleaner.clean(dirty_xml,path)
    rescue => e
      puts "Failed to clean #{path}: #{e.short}".red
      fails[:clean] << path
      next
    end
    
    begin
      pbcore = ingester.ingest_xml(clean_xml)
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
      puts "Successfully added '#{path}' (id:#{pbcore.id})".green
      success << path
    end
    
  end
  
  puts "SUMMARY"
  
  puts "processed #{target_dir}" if target_dir
  fails.each{|type,list|
    puts "#{fails[type].count} failed to #{type}:\n#{fails[type].join("\n")}".red unless fails[type].empty?
  }
  puts "#{success.count} succeeded".green
  
  puts "DONE"
end
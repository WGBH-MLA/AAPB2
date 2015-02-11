require_relative 'downloader'
require_relative 'uncollector'
require_relative 'cleaner'
require_relative 'pb_core_ingester'

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
  
  failed_to_read = []
  failed_to_clean = []
  failed_to_validate = []
  failed_to_add = []
  failed_other = []
  success = []
  
  cleaner = Cleaner.new
  ingester = PBCoreIngester.new
  
  abort 'One optional parameter: number of days back to look. Gets all if missing.' if ARGV.count > 1
  
  target_dir = Downloader::download_to_directory_and_link(ARGV.first.to_i)
  
  Dir.entries(target_dir).reject{|file_name|
    ['.','..'].include?(file_name)
  }.each do |file_name|
    
    path = "#{target_dir}/#{file_name}"
    
    begin
      dirty_xml = File.read(path)
    rescue => e
      puts "Failed to read #{path}: #{e.message}".red
      failed_to_read << path
      next
    end
    
    begin
      clean_xml = cleaner.clean(dirty_xml,path)
    rescue => e
      puts "Failed to clean #{path}: #{e.message}".red
      failed_to_clean << path
      next
    end
    
    begin
      pbcore = ingester.ingest_xml(clean_xml)
    rescue PBCoreIngester::ValidationError => e
      puts "Failed to validate #{path}: #{e.message}".red
      failed_to_validate << path
      next
    rescue PBCoreIngester::SolrError => e
      puts "Failed to add #{path}: #{e.message}".red
      failed_to_add << path
      next
    rescue => e
      puts "Other error on #{path}: #{e.message}".red
      failed_other << path
      next
    else
      puts "Successfully added '#{path}' (id:#{pbcore.id})".green
      success << path
    end
    
  end
  
  puts "DONE"
  puts "#{failed_to_read.count} failed to load".red if !failed_to_read.empty?
  puts "#{failed_to_clean.count} failed to clean".red if !failed_to_clean.empty?
  puts "#{failed_to_validate.count} failed to validate".red if !failed_to_validate.empty?
  puts "#{failed_to_add.count} failed to add".red if !failed_to_add.empty?
  puts "#{failed_other.count} failed other".red if !failed_other.empty?
  puts "#{success.count} succeeded"
end
require_relative 'downloader'
require_relative 'uncollector'
require_relative 'cleaner'
require_relative 'pb_core_ingester'
require_relative '../app/models/validated_pb_core'

class Exception
  def short
    self.message + "\n" + self.backtrace[0..2].join("\n")
  end
end

if __FILE__ == $0
  
  log = STDERR
  cleaner = Cleaner.new
  ingester = PBCoreIngester.new
  
  abort 'No arguments allowed' unless ARGV.empty?
  
  target_dir = Downloader::download_to_directory_and_link
  
  Dir.entries(target_dir).reject{|path|
    ['.','..'].include?(path)
  }.each do |path|
    dirty_xml = File.read("#{target_dir}/#{path}")
    
    begin
      clean_xml = cleaner.clean(dirty_xml,path)
    rescue => e
      log << "Cleaner failed:\n#{dirty_xml}\n#{e.short}\n"
      next
    end
    
    begin
      ingester.ingest_xml(clean_xml)
    rescue => e
      log << "Ingest failed:\nBEFORE:#{dirty_xml}\nAFTER:\n#{clean_xml}\n#{e.short}\n"
      next
    end
    
  end
end
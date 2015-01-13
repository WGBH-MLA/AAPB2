require_relative 'downloader'
require_relative 'uncollector'
require_relative 'cleaner'
require_relative '../app/models/validated_pb_core'

class Exception
  def short
    self.message + "\n" + self.backtrace[0..2].join("\n")
  end
end

if __FILE__ == $0
  
  log = STDERR
  
  if ARGV.count > 2
    abort "Expects at most 2 args, not #{ARGV.count}"
  end
  
  cleaner = Cleaner.new
  target_dir = File.dirname(File.dirname(__FILE__))+'/'+Downloader::TARGET+'/'+Time.now.strftime('%v_%H:%M:%S')
  Dir.mkdir(target_dir)
  
  [0,1].each do |digitized|
    downloader = Downloader.new(digitized, *ARGV.map{|arg| arg.to_i})
    downloader.download_to_directory(target_dir)
  end
  
  Dir.entries(target_dir).reject{|path|
    ['.','..'].include?(path)
  }.each{|path|
    log << "uncollect #{path}\n"
    Uncollector.uncollect("#{target_dir}/#{path}")
  }
  
  Dir.entries(target_dir).reject{|path|
    ['.','..'].include?(path)
  }.each do |path|
    dirty_xml = File.read("#{target_dir}/#{path}")
    
    begin
      clean_xml = cleaner.clean(dirty_xml,path)
    rescue => e
      puts "Cleaner.clean died:\n#{dirty_xml}\n#{e.short}"
      next
    end
    
    begin
      pbcore = ValidatedPBCore.new(clean_xml)
    rescue => e
      puts "ValidatedPBCore.new died:\nBEFORE:#{dirty_xml}\nAFTER:\n#{clean_xml}\n#{e.short}"
      next
    end
    
    puts "VALID: #{pbcore.id}"
  end
end
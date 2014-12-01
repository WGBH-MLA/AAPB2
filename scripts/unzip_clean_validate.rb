require_relative 'unzipper'
require_relative 'cleaner'
require_relative '../app/models/validated_pb_core'

class Exception
  def short
    self.message + "\n" + self.backtrace[0..2].join("\n")
  end
end

if __FILE__ == $0
  if ARGV.count > 2
    abort "Expects at most 2 args, not #{ARGV.count}"
  end
  
  unzipper = Unzipper.new(*ARGV)
  cleaner = Cleaner.new
  
  unzipper.each do |dirty_xml, name|
    begin
      clean_xml = cleaner.clean(dirty_xml)
    rescue => e
      puts "Cleaner died:\n#{dirty_xml}\n#{e.short}"
      next
    end
    
    begin
      pbcore = ValidatedPBCore.new(clean_xml)
    rescue => e
      puts "ValidatedPBCore died:\nBEFORE:#{dirty_xml}\nAFTER:\n#{clean_xml}\n#{e.short}"
      next
    end
    
    puts "VALID: #{pbcore.id}"
  end
end
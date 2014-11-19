require_relative 'unzipper'
require_relative 'cleaner'
require_relative '../app/models/validated_pb_core'

class Exception
  def short
    self.message + "\n" + self.backtrace[0..2].join("\n")
  end
end

if __FILE__ == $0
  if ARGV.count != 1
    abort "Expects one argument, not #{ARGV.count}"
  end
  
  unzipper = Unzipper.new(ARGV[0])
  unzipper.each do |dirty_xml|
    begin
      clean_xml = Cleaner.clean(dirty_xml)
    rescue => e
      abort "Cleaner died:\n#{dirty_xml}\n#{e.short}"
    end
    
    begin
      pbcore = ValidatedPBCore.new(clean_xml)
    rescue => e
      abort "ValidatedPBCore died:\nBEFORE:#{dirty_xml}\nAFTER:\n#{clean_xml}\n#{e.short}"
    end
    
    puts "VALID: #{pbcore.id}"
  end
end
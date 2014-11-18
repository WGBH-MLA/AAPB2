require_relative 'unzipper'
require_relative 'cleaner'
require_relative '../app/models/validated_pb_core'

if __FILE__ == $0
  if ARGV.count != 1
    abort "Expects one argument, not #{ARGV.count}"
  end
  
  unzipper = Unzipper.new(ARGV[0])
  unzipper.each do |dirty_xml|
    clean_xml = Cleaner.clean(dirty_xml)
    begin
      pbcore = ValidatedPBCore.new(clean_xml)
      puts "VALID: #{pbcore.id}"
    rescue => e
      abort "This isn't clean enough:\nBEFORE:#{dirty_xml}\nAFTER:\n#{clean_xml}\n#{e}"
    end
  end
end
require_relative '../app/models/validated_pb_core'

module Cleaner
  def self.clean(dirty_xml)
    # TODO
    clean_xml = dirty_xml
    clean_xml
  end
end

if __FILE__ == $0
  if ARGV.count != 1
    abort "Expects one argument, not #{ARGV.count}"
  end
  
  dirty_xml = File.read(ARGV[0])
  puts Cleaner.clean(dirty_xml)
end
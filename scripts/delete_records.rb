require_relative '../lib/rails_stub'
require_relative '../app/models/exhibit'
require_relative 'lib/downloader'
require_relative 'lib/cleaner'
require_relative 'lib/pb_core_ingester'
require 'logger'
require 'rake'

args = ARGV
ingester = PBCoreIngester.new
unless args.all? { |id| %r{\Acpb-aacip[\-_\/][0-9]{1,3}[\-_\/][a-zA-Z0-9]+\z} =~ id }
  puts "Got a non-GUID argument! That's not cool!"
  exit 1
end
ingester.delete_records(args)

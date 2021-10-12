require_relative 'lib/deleter'

# bundle exec ruby scripts/delete_records.rb cpb-aacip-12-34567 cpb-aacip-1234567
args = ARGV
Deleter.new(args).delete

require_relative 'lib/deleter'

args = ARGV
Deleter.new(args).delete

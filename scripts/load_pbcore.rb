require 'rsolr'
require_relative '../app/models/validated_pbcore'
require 'date' # NameError deep in Solrizer without this.

solr = RSolr.connect url: 'http://localhost:8983/solr/' # TODO: read config/solr.yml

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
failed_to_validate = []
failed_to_add = []
success = []

ARGV.each do |name|
  puts "Reading #{name}"
  
  begin
    xml = File.read(name)
  rescue => e
    puts "Failed to read '#{name}': #{e.message}".red
    failed_to_read << name
    next
  end
  
  begin
    pbcore = ValidatedPBCore.new(xml)
  rescue => e
    puts "Failed to validate '#{name}: #{e.message}".red
    failed_to_validate << name
    next
  end
  
  begin
    solr.add(pbcore.to_solr)
  rescue => e
    puts "Failed to add '#{name}': #{e.message}".red
    failed_to_add << name
    next
  end
  
  puts "Successfully added '#{name}' (id:#{pbcore.id})".green
  success << name
  
end

puts "DONE"
puts "#{failed_to_read.count} failed to load" if !failed_to_read.empty?
puts "#{failed_to_validate.count} failed to validate" if !failed_to_validate.empty?
puts "#{failed_to_add.count} failed to add" if !failed_to_add.empty?
puts "#{success.count} succeeded"
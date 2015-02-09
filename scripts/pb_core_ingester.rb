require 'rsolr'
require_relative '../app/models/validated_pb_core'
require 'date' # NameError deep in Solrizer without this.

class PBCoreIngester
   
  attr_reader :solr
  
  def initialize(url='http://localhost:8983/solr/')
    @solr = RSolr.connect(url: url) # TODO: read config/solr.yml
  end
  
  # TODO: maybe light session management? If we don't go in that direction, this should just be a module.
  
  def delete_all
    @solr.delete_by_query('*:*')
    @solr.commit
  end
  
  def ingest(path)

    begin
      xml = File.read(path)
    rescue StandardError => e
      raise ReadError.new(e)
    end

    ingest_xml(xml)
    
  end
  
  def ingest_xml(xml)
    
    begin
      pbcore = ValidatedPBCore.new(xml)
    rescue StandardError => e
      raise ValidationError.new(e)
    end

    begin
      @solr.add(pbcore.to_solr)
      @solr.commit
    rescue StandardError => e
      raise SolrError.new(e)
    end
    
    pbcore
  
  end
  
  class ChainedError < StandardError
    def initialize(e)
      @base_error = e
    end
    def message
      @base_error.message
    end
  end
  class ReadError < ChainedError
  end
  class ValidationError < ChainedError
  end
  class SolrError < ChainedError
  end
  
end

if __FILE__ == $0
  
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
  
  ingester = PBCoreIngester.new

  ARGV.each do |path|
    begin
      pbcore = ingester.ingest(path)
    rescue PBCoreIngester::ReadError => e
      puts "Failed to read '#{path}': #{e.message}".red
      failed_to_read << path
    rescue PBCoreIngester::ValidationError => e
      puts "Failed to validate '#{path}: #{e.message}".red
      failed_to_validate << path
    rescue PBCoreIngester::SolrError => e
      puts "Failed to add '#{path}': #{e.message}".red
      failed_to_add << path
    else
      puts "Successfully added '#{path}' (id:#{pbcore.id})".green
      success << path
    end
  end

  puts "DONE"
  puts "#{failed_to_read.count} failed to load" if !failed_to_read.empty?
  puts "#{failed_to_validate.count} failed to validate" if !failed_to_validate.empty?
  puts "#{failed_to_add.count} failed to add" if !failed_to_add.empty?
  puts "#{success.count} succeeded"
end
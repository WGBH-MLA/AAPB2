require 'rsolr'
require_relative '../app/models/validated_pb_core'
require 'date' # NameError deep in Solrizer without this.

class PBCoreIngester
    
  def initialize(url='http://localhost:8983/solr/')
    @solr = RSolr.connect(url: url) # TODO: read config/solr.yml
  end
  
  # TODO: maybe batch management? If we don't go in that direction, this should just be a module.
  
  def ingest(path)

    begin
      xml = File.read(path)
    rescue StandardError => e
      raise ReadError.new(e)
    end

    begin
      pbcore = ValidatedPBCore.new(xml)
    rescue StandardError => e
      raise ValidationError.new(e)
    end

    begin
      @solr.add(pbcore.to_solr)
    rescue StandardError => e
      raise SolrError.new(e)
    end
    
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

# TODO: command-line
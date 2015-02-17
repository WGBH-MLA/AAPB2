require 'rsolr'
require_relative '../../app/models/validated_pb_core'
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
    rescue => e
      raise ReadError.new(e)
    end

    ingest_xml(xml)
    
  end
  
  def ingest_xml(xml)
    
    begin
      pbcore = ValidatedPBCore.new(xml)
    rescue => e
      raise ValidationError.new(e)
    end

    begin
      @solr.add(pbcore.to_solr)
      @solr.commit
    rescue => e
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
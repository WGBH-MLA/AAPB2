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

    case xml[0..100] # just look at the start of the file.
    when /<pbcoreCollection/
      Uncollector::uncollect_string(xml).each do |document|
        ingest_xml(document)
      end
    when /<pbcoreDescriptionDocument/
      ingest_xml(xml)
    else
      raise ValidationError.new("Neither pbcoreCollection nor pbcoreDocument. #{path}: #{xml[0..100]}")
    end  
    
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
    # Sorry, this is more java-ish than ruby-ish,
    # but downstream I want to distinguish different
    # error types, AND I want to know the root cause.
    # This makes that possible.
    def initialize(e)
      @base_error = e
    end
    def message
      @base_error.message + "\n" + @base_error.backtrace[0..2].join("\n") + "\n..."
    end
  end
  class ReadError < ChainedError
  end
  class ValidationError < ChainedError
  end
  class SolrError < ChainedError
  end
  
end
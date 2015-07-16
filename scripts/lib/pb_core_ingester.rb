require 'rsolr'
require 'date' # NameError deep in Solrizer without this.
require 'logger'
require_relative '../../app/models/validated_pb_core'
require_relative 'uncollector'
require_relative 'cleaner'
require_relative 'null_logger'
require_relative 'mount_validator'
require_relative '../../lib/solr'

class PBCoreIngester

  def initialize(opts)
    # TODO: hostname and corename from config?
    @solr = Solr.instance.connect
    @solr.get('../admin/cores')['status']['blacklight-core']['dataDir'].tap{|data_dir|
      MountValidator.validate_mount("#{data_dir}index", 'solr index') unless opts[:is_same_mount]
    }
    $LOG ||= NullLogger.new
  end

  def self.load_fixtures
    # This is a test in its own right elsewhere.
    ingester = PBCoreIngester.new(is_same_mount: true)
    ingester.delete_all
    Dir['spec/fixtures/pbcore/clean-*.xml'].each do |pbcore|
      ingester.ingest(path: pbcore)
    end
  end

  # TODO: maybe light session management? If we don't go in that direction, this should just be a module.

  def delete_all
    @solr.delete_by_query('*:*')
    commit
  end

  def ingest(opts)
    path = opts[:path]
    is_batch_commit = opts[:is_batch_commit]
    cleaner = Cleaner.new

    begin
      xml = File.read(path)
    rescue => e
      raise ReadError.new(e)
    end

    @md5s_seen = Set.new

    xml_top = xml[0..100] # just look at the start of the file.
    case xml_top
    when /<pbcoreCollection/
      $LOG.info("Read pbcoreCollection from #{path}")
      Uncollector.uncollect_string(xml).each do |document|
        md5 = Digest::MD5.hexdigest(document)
        if @md5s_seen.include?(md5)
          # Documents are often repeated in AMS exports.
          $LOG.info("Skipping already seen md5 #{md5}")
        else
          @md5s_seen.add(md5)
          begin
            ingest_xml_no_commit(cleaner.clean(document))
          rescue => e
            id_extracts = document.scan(/<pbcoreIdentifier[^>]*>[^<]*<[^>]*>/)
            $LOG.warn("Error during ingest of #{id_extracts}: #{e.message}")
            raise e
          end
        end
      end
    when /<pbcoreDescriptionDocument/
      ingest_xml_no_commit(cleaner.clean(xml))
    else
      fail ValidationError.new("Neither pbcoreCollection nor pbcoreDocument. #{path}: #{xml_top}")
    end
    begin
      commit unless is_batch_commit
    rescue => e
      raise SolrError.new(e)
    end
  end

  def commit
    @solr.commit
  end

  def ingest_xml_no_commit(xml)
    begin
      pbcore = ValidatedPBCore.new(xml)
    rescue => e
      raise ValidationError.new(e)
    end

    begin
      @solr.add(pbcore.to_solr)
    rescue => e
      raise SolrError.new(e)
    end

    $LOG.info("Updated solr record #{pbcore.id}")

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
      if @base_error.respond_to?(:message)
        @base_error.message + "\n" + @base_error.backtrace[0..2].join("\n") + "\n..."
      else
        @base_error
      end
    end
  end
  class ReadError < ChainedError
  end
  class ValidationError < ChainedError
  end
  class SolrError < ChainedError
  end
end

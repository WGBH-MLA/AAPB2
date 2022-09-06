require 'rsolr'
require 'date' # NameError deep in Solrizer without this.
require 'logger'
require_relative '../../app/models/validated_pb_core'
require_relative 'uncollector'
require_relative 'cleaner'
require_relative 'null_logger'
require_relative 'zipper'
require_relative '../../lib/solr'
require_relative '../../app/helpers/solr_guid_fetcher'

class PBCoreIngester
  attr_reader :errors
  attr_reader :success_count

  include SolrGUIDFetcher

  def initialize
    # TODO: hostname and corename from config?
    @solr = Solr.instance.connect
    $LOG ||= NullLogger.new
    @errors = Hash.new([])
    @success_count = 0
  end

  def self.load_fixtures(*globs)
    # This is a test in its own right elsewhere.
    ingester = PBCoreIngester.new
    ingester.delete_all
    # If no globs were passed in, default to all "clean" PBCore fixtures.
    globs << 'spec/fixtures/pbcore/clean-*.xml' if globs.empty?
    # Get a list of all file paths from all the globs.
    all_paths = globs.map { |glob| Dir[glob] }.flatten.uniq
    all_paths.each do |path|
      ingester.ingest(path: path)
    end
  end

  def delete_all
    @solr.delete_by_query('*:*')
    commit
  end

  def delete_records(guids)
    guids.each do |guid|
      puts "Deleting #{guid}"
      resp = @solr.get('select', params: { q: "id:#{guid}" })
      docs = resp['response']['docs'] if resp['response'] && resp['response']['docs']

      # can't delete what you can't query
      next unless docs && docs.count == 1
      puts "Ready to delete #{guid}"
      @solr.delete_by_query(%(id:#{guid}))
      commit
    end
    puts 'Done!'
  end

  def ingest(opts)
    path = opts[:path]
    is_batch_commit = opts[:is_batch_commit]
    cleaner = Cleaner.instance

    begin
      xml = Zipper.read(path, opts[:is_leave_files])
      xml = convert_non_utf8_characters(xml)
    rescue => e
      record_error(e, path)
      return
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
            @success_count += 1
          rescue => e
            id_extracts = document.scan(/<pbcoreIdentifier[^>]*>[^<]*<[^>]*>/)
            record_error(e, path, id_extracts)
          end
        end
      end
    when /<pbcoreDescriptionDocument/
      begin
        ingest_xml_no_commit(cleaner.clean(xml))
        @success_count += 1
      rescue => e
        record_error(e, path)
      end
    else
      e = ValidationError.new("Neither pbcoreCollection nor pbcoreDocument. #{xml_top}")
      record_error(e, path)
    end

    commit unless is_batch_commit
  end

  def record_error(e, path, id_extracts = '')
    message = "#{path} #{id_extracts}: #{e.message}"
    $LOG.warn(message)
    @errors["#{e.class}: #{e.message.split(/\n/).first}"] += [message]
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
      # From SolrGUIDFetcher
      fetch_all_from_solr(pbcore.id, @solr).each do |id|
        $LOG.info("Removing solr record with ID: #{pbcore.id}")
        @solr.delete_by_id(id)
      end

      @solr.add(pbcore.to_solr)
    rescue => e
      raise SolrError.new(e)
    end

    $LOG.info("Updated solr record #{pbcore.id}")

    pbcore
  end

  private

  def convert_non_utf8_characters(str)
    # Convert vertical tabs to newline + tab
    str.gsub("\v", "\n\t")
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
  class ValidationError < ChainedError
  end
  class SolrError < ChainedError
  end
end

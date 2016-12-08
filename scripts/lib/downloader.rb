require 'open-uri'
require 'rexml/xpath'
require 'rexml/document'
require 'set'
require 'fileutils'
require_relative 'zipper'
require_relative 'null_logger'
require_relative '../../lib/solr'
require_relative 'query_maker'
require 'pry'

class Downloader
  MAX_ROWS = 10_000
  KEY = 'b5f3288f3c6b6274c3455ec16a2bb67a'.freeze
  # From docs at https://github.com/avpreserve/AMS/blob/master/documentation/ams-web-services.md
  # ie, this not sensitive.
  $LOG ||= NullLogger.new

  def initialize(opts = {})
    check_expected_keys(opts)

    since = if opts.key?(:days)
              (Time.now - opts[:days] * 24 * 60 * 60).strftime('%Y%m%d')
            else
              '20000101' #ie, beginning of time.
            end
    check_since(since)

    @options = opts
    @options[:since] = since
    @options[:dirname] = Time.now.strftime('%F_%T.%6N')
  end

  def run
    mkdir_and_cd(@options[:dirname])

    if @options[:query]
      process_query(@options[:query])
    end

    if @options[:ids]
      download_ids_to_directory(@options[:ids])
    else
      @options[:page] ||= 1 # API is 1-indexed, but also returns page 1 results for page 0.
      download_pages_to_directory(@options[:page])
    end

    clean_downloads_directory(@options[:dirname])
    Dir.pwd
  end

  private

  def http_get(url)
    URI.parse(url).read(read_timeout: 240, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
  end

  def mkdir_and_cd(name)
    Dir.chdir(Rails.root)
    path = "tmp/downloads/#{name}"
    FileUtils.mkdir_p(path)
    Dir.chdir(path)

    Dir.chdir('..')
    link_name = 'LATEST'
    File.unlink(link_name) if File.symlink?(link_name)
    raise "Did not expect '#{link_name}'" if File.exist?(link_name)
    File.symlink(name, link_name)

    Dir.chdir(link_name)
  end

  def clean_downloads_directory(dirname)
    old_dirs = []
    path = "#{Rails.root}/tmp/downloads"

    Dir.glob("#{path}/**").each do |dir|
      old_dirs << dir unless dir == "#{path}/#{dirname}" || dir == "#{path}/LATEST"
    end

    FileUtils.rm_rf(old_dirs)
  end

  def download_pages_to_directory(start_page)
    download_by_page(start_page) do |collection, page|
      name = "page-#{page}.pbcore"

      # Need code to clean out directory

      Zipper.write(name, collection)
      $LOG.info("Wrote #{File.join([Dir.pwd, name])}")
    end
  end

  def check_expected_keys(options)
    raise("Unexpected keys: #{options}") unless Set.new(options.keys).subset?(
      Set[
        :days, :page, :ids, :query, # modes
        :is_just_reindex # flags
    ])
  end

  def check_since(since)
    since.match(/(\d{4})(\d{2})(\d{2})/).tap do |match|
      raise("Expected YYYYMMDD, not '#{since}'") unless
        match &&
        match[1].to_i < 3000 &&
        match[2].to_i.instance_eval { |m| (1 <= m) && (m <= 12) } &&
        match[3].to_i.instance_eval { |d| (1 <= d) && (d <= 31) }
    end
  end

  def process_query(query)
    q = QueryMaker.translate(query)
    $LOG.info("Query solr for #{query}")

    @options[:ids] = RSolr.connect(url: 'http://localhost:8983/solr/').get('select', params: {
                                                                         q: q, fl: 'id', rows: MAX_ROWS })['response']['docs'].map { |doc| doc['id'] }
    raise("Got back more than #{MAX_ROWS} from query") if @options[:ids].size > MAX_ROWS
  end

  def download_ids_to_directory(ids)
    ids.each do |id|
      id = id.gsub(/[^[:ascii:]]/, '').gsub(/[^[:print:]]/, '')
      short_id = id.sub(/.*[_\/]/, '')
      content = if @options[:is_just_reindex]
                  $LOG.info("Query solr for #{id}")
                  # TODO: hostname and corename from config?
                  Solr.instance.connect
                      .get('select', params: {
                             qt: 'document', id: id
                           })['response']['docs'][0]['xml']
                else
                  url = "https://ams.americanarchive.org/xml/pbcore/key/#{KEY}/guid/#{short_id}"
                  $LOG.info("Downloading #{url}")
                  http_get(url)
      end
      Zipper.write("#{short_id}.pbcore", content)
    end
  end

  def download_by_page(page)
    loop do
      url = "https://ams.americanarchive.org/xml/pbcore/key/#{KEY}/modified_date/#{@options[:since]}/page/#{page}"
      content = nil
      until content
        begin
          $LOG.info("Trying #{url}")
          content = http_get(url)
        rescue Net::ReadTimeout
          $LOG.warn('Timeout. Retrying in 10...')
          sleep 10
        end
      end
      if content =~ /^<error>/
        $LOG.info("Paged past end of results: page #{page}")
        return
      else
        $LOG.info("Got page #{page}")
        yield(content, page)
        page += 1
      end
    end
  end
end

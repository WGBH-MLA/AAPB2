require 'open-uri'
require 'rexml/xpath'
require 'rexml/document'
require 'set'
require 'fileutils'
require_relative 'zipper'
require_relative 'null_logger'
require_relative 'mount_validator'
require_relative '../../lib/solr'
require_relative 'query_maker'

class Downloader
  MAX_ROWS = 10_000
  KEY = 'b5f3288f3c6b6274c3455ec16a2bb67a'
  # From docs at https://github.com/avpreserve/AMS/blob/master/documentation/ams-web-services.md
  # ie, this not sensitive.
  $LOG ||= NullLogger.new

  def initialize(since)
    @since = since
    since.match(/(\d{4})(\d{2})(\d{2})/).tap do |match|
      fail("Expected YYYYMMDD, not '#{since}'") unless
        match &&
        match[1].to_i < 3000 &&
        match[2].to_i.instance_eval { |m| (1 <= m) && (m <= 12) } &&
        match[3].to_i.instance_eval { |d| (1 <= d) && (d <= 31) }
    end
  end

  def self.download_to_directory_and_link(opts={})
    fail("Unexpected keys: #{opts}") unless Set.new(opts.keys).subset?(
      Set[
        :days, :page, :ids, :query, # modes
        :is_same_mount, :is_just_reindex # flags
      ])
    now = Time.now.strftime('%F_%T.%6N')
    if opts[:query]
      dirname = "#{now}_by_query_#{opts[:query].gsub(/\W+/, '-')}"
      q = QueryMaker.translate(opts[:query])
      $LOG.info("Query solr for #{opts[:query]}")
      opts[:ids] = RSolr.connect(url: 'http://localhost:8983/solr/').get('select', params: {
                                                                           q: q, fl: 'id', rows: MAX_ROWS })['response']['docs'].map { |doc| doc['id'] }
      fail("Got back more than #{MAX_ROWS} from query") if opts[:ids].size > MAX_ROWS
    end
    if opts[:ids]
      dirname ||= "#{now}_by_ids_#{opts[:ids].size}"
      mkdir_and_cd(dirname, opts[:is_same_mount])
      opts[:ids].each do |id|
        id = id.gsub(/[^[:ascii:]]/,'').gsub(/[^[:print:]]/,'')
        short_id = id.sub(/.*[_\/]/, '')
        content = if opts[:is_just_reindex]
                    $LOG.info("Query solr for #{id}")
          # TODO: hostname and corename from config?
                    Solr.instance.connect
                    .get('select', params: {
                           qt: 'document', id: id
                         })['response']['docs'][0]['xml']
                  else
                    url = "https://ams.americanarchive.org/xml/pbcore/key/#{KEY}/guid/#{short_id}"
                    $LOG.info("Downloading #{url}")
                    URI.parse(url).read(read_timeout: 240)
        end
        Zipper.write("#{short_id}.pbcore", content)
      end
    else
      opts[:page] ||= 1 # API is 1-indexed, but also returns page 1 results for page 0.
      since = if opts[:days]
                (Time.now - opts[:days] * 24 * 60 * 60).strftime('%Y%m%d')
              else
                '20000101' # ie, beginning of time.
              end
      mkdir_and_cd("#{now}_since_#{since}_starting_page_#{opts[:page]}", opts[:is_same_mount])
      downloader = Downloader.new(since)
      downloader.download_to_directory(opts[:page])
    end
    Dir.pwd
  end

  def self.mkdir_and_cd(name, is_same_mount)
    Dir.chdir(Rails.root)
    path = "tmp/downloads/#{name}"
    FileUtils.mkdir_p(path)
    Dir.chdir(path)
    MountValidator.validate_mount(Dir.pwd, 'pbcore downloads') unless is_same_mount

    Dir.chdir('..')
    link_name = 'LATEST'
    File.unlink(link_name) if File.symlink?(link_name)
    fail "Did not expect '#{link_name}'" if File.exist?(link_name)
    File.symlink(name, link_name)

    Dir.chdir(link_name)
  end

  def download_to_directory(start_page)
    download(start_page) do |collection, page|
      name = "page-#{page}.pbcore"
      Zipper.write(name, collection)
      $LOG.info("Wrote #{File.join([Dir.pwd, name])}")
    end
  end

  def download(page)
    loop do
      url = "https://ams.americanarchive.org/xml/pbcore/key/#{KEY}/modified_date/#{@since}/page/#{page}"
      content = nil
      until content
        begin
          $LOG.info("Trying #{url}")
          content = URI.parse(url).read(read_timeout: 240)
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

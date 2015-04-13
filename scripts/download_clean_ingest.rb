require_relative 'lib/downloader'
require_relative 'lib/cleaner'
require_relative 'lib/pb_core_ingester'
require 'logger'
require 'rake'

class Exception
  def short
    message + "\n" + backtrace[0..2].join("\n")
  end
end

class ParamsError < StandardError
end

class DownloadCleanIngest
  def const_init(name)
    const_name = name.upcase.gsub('-', '_')
    flag_name = "--#{name}"
    begin
      # to avoid "warning: already initialized constant" in tests.
      DownloadCleanIngest.const_get(const_name)
    rescue NameError
      DownloadCleanIngest.const_set(const_name, flag_name)
    end
  end

  def download(opts)
    [Downloader.download_to_directory_and_link(
      { is_same_mount: @is_same_mount, is_just_reindex: @is_just_reindex }.merge(opts)
    )]
  end

  def initialize(argv)
    orig = argv.clone

    %w(all back query dirs files ids id-files).each do |name|
      const_init(name)
    end

    %w(batch-commit same-mount stdout-log just-reindex skip-sitemap).each do |name|
      flag_name = const_init(name)
      variable_name = "@is_#{name.gsub('-', '_')}"
      instance_variable_set(variable_name, argv.include?(flag_name))
      argv.delete(flag_name)
    end

    mode = argv.shift
    args = argv

    fail("#{JUST_REINDEX} should only be used with #{IDS} or #{QUERY} modes") if @is_just_reindex && ![IDS, ID_FILES, QUERY].include?(mode)

    log_init(orig)
    $LOG.info("START: Process ##{Process.pid}: #{__FILE__} #{orig.join(' ')}")

    @flags = { is_same_mount: @is_same_mount, is_just_reindex: @is_just_reindex }

    begin
      case mode

      when ALL
        fail ParamsError.new unless args.count < 2 && (!args.first || args.first.to_i > 0)
        target_dirs = download(page: args.first.to_i)

      when BACK
        fail ParamsError.new unless args.count == 1 && args.first.to_i > 0
        target_dirs = download(days: args.first.to_i)

      when QUERY
        fail ParamsError.new unless args.count == 1
        target_dirs = download(query: args.first)

      when IDS
        fail ParamsError.new unless args.count >= 1
        target_dirs = download(ids: args)

      when ID_FILES
        fail ParamsError.new unless args.count >= 1
        ids = args.map { |id_file| File.readlines(id_file).map { |line| line.strip } }.flatten
        target_dirs = download(ids: ids)

      when DIRS
        fail ParamsError.new if args.empty? || args.map { |dir| !File.directory?(dir) }.any?
        target_dirs = args

      when FILES
        fail ParamsError.new if args.empty?
        @files = args

      else
        fail ParamsError.new
      end
    rescue ParamsError
      abort usage_message
    end

    @files ||= target_dirs.map do |target_dir|
      Dir.entries(target_dir)
      .reject { |file_name| ['.', '..'].include?(file_name) }
      .map { |file_name| "#{target_dir}/#{file_name}" }
    end.flatten.sort
  end

  def log_init(argv)
    log_file_name = if @is_stdout_log
                      $stdout
                    else
                      File.join(
                        File.dirname(File.dirname(__FILE__)), 'log',
                        "ingest-#{argv.grep(/--/).map { |a| a.sub('--', '') }.join('-')}.log"
                      )
    end
    $LOG = Logger.new(log_file_name, 'daily')
    $LOG.formatter = proc do |severity, datetime, _progname, msg|
      "#{severity} [#{datetime.strftime('%Y-%m-%d %H:%M:%S')}]: #{msg}\n"
    end
    puts "logging to #{log_file_name}"
  end

  def usage_message
    <<-EOF.gsub(/^ {4}/, '')
      USAGE: #{File.basename(__FILE__)}
               [#{BATCH_COMMIT}] [#{SAME_MOUNT}] [#{STDOUT_LOG}]
               [#{JUST_REINDEX}] [#{SKIP_SITEMAP}]
               ( #{ALL} [PAGE] | #{BACK} DAYS | #{QUERY} 'QUERY'
                 | #{IDS} ID ... | #{ID_FILES} ID_FILE ...
                 | #{FILES} FILE ... | #{DIRS} DIR ... )

      boolean flags:
        #{BATCH_COMMIT}: Optionally, make just one commit at the end, rather than
          one commit per file.
        #{SAME_MOUNT}: Optionally, allow same mount point for the script and the
          solr index. This is what you want in development, but the default, to
          disallow this, would have stopped me from running out of disk many times.
        #{STDOUT_LOG}: Optionally, log to stdout, rather than a log file.
        #{JUST_REINDEX}: Rather than querying the AMS, query the local solr. This
          is typically used when the indexing strategy has changed, but the AMS
          data has not changed.
        #{SKIP_SITEMAP}: Do not regenerate sitemap.xml. If no new records are
          ingested, the sitemaps will not change, and regeneration can be skipped.

      mutually exclusive modes:
        #{ALL}: Download, clean, and ingest all PBCore from the AMS. Optionally,
          supply a results page to begin with.
        #{BACK}: Download, clean, and ingest only those records updated in the
          last N days. (I don't trust the underlying API, so give yourself a
          buffer if you use this for daily updates.)
        #{QUERY}: First obtain a list of IDs to update using the url query fragment.
          Unless #{JUST_REINDEX} is given, these records will be re-downloaded,
          cleaned, and ingested.
        #{IDS}: Download (or query), clean, and ingest records with the given IDs.
          Will usually be used in conjunction with #{BATCH_COMMIT}, rather than
          committing after each record.
        #{ID_FILES}: Read the files, and then download (or query), clean, and
          ingest records with the given IDs. Again, this will usually be used in
          conjunction with #{BATCH_COMMIT}, rather than committing after each record.
        #{FILES}: Clean and ingest the given files.
        #{DIRS}: Clean and ingest the given directories. (While "#{FILES} dir/*"
          could suffice in many cases, for large directories it might not work,
          and this is easier than xargs.)
      EOF
  end

  def process
    fails = { read: [], clean: [], validate: [], add: [], other: [] }
    success = []
    ingester = PBCoreIngester.new(is_same_mount: @is_same_mount)

    @files.each do |path|
      begin
        ingester.ingest(path: path, is_batch_commit: @is_batch_commit)
      rescue PBCoreIngester::ReadError => e
        $LOG.warn("Failed to read #{path}: #{e.short}")
        fails[:read] << path
        next
      rescue PBCoreIngester::ValidationError => e
        $LOG.warn("Failed to validate #{path}: #{e.short}")
        fails[:validate] << path
        next
      rescue PBCoreIngester::SolrError => e
        $LOG.warn("Failed to add #{path}: #{e.short}")
        fails[:add] << path
        next
      rescue => e
        $LOG.warn("Other error on #{path}: #{e.short}")
        fails[:other] << path
        next
      else
        $LOG.info("Successfully added '#{path}' #{'but not committed' if @is_batch_commit}")
        success << path
      end
    end

    if @is_batch_commit
      $LOG.info('Starting one big commit...')
      ingester.commit
      $LOG.info('Finished one big commit.')
    end

    # TODO: Investigate whether optimization is worth it. Requires a lot of disk and time.
    # puts 'Ingest complete; Begin optimization...'
    # ingester.optimize

    unless @is_skip_sitemap
      $LOG.info('Starting sitemap generation...')
      $LOG.info(`rake blacklight:sitemap`) # TODO: figure out the right way to do this.
      $LOG.info('Finished sitemap generation.')
    end

    $LOG.info('SUMMARY')

    fails.each {|type, list|
      $LOG.warn("#{list.count} failed to #{type}:\n#{list.join("\n")}") unless list.empty?
    }
    $LOG.info("#{success.count} succeeded")

    $LOG.info('DONE')
  end
end

if __FILE__ == $PROGRAM_NAME
  DownloadCleanIngest.new(ARGV).process
end

require_relative 'lib/downloader'
require_relative 'lib/cleaner'
require_relative 'lib/pb_core_ingester'
require 'logger'

class Exception
  def short
    message + "\n" + backtrace[0..2].join("\n")
  end
end

class ParamsError < StandardError
end

class DownloadCleanIngest
  ONE_COMMIT = '--one-commit'
  SAME_MOUNT = '--same-mount'
  ALL = '--all'
  BACK = '--back'
  DIRS = '--dirs'
  FILES = '--files'
  IDS = '--ids'

  def log_init()
    log_file_name = File.join(
      File.dirname(File.dirname(__FILE__)), 
      "log/ingest-#{ARGV[0..4].map{|a| a.sub('--','')}.join('-')}.log"
    )
    $LOG = Logger.new(log_file_name)
    puts "logging to #{log_file_name}"
    $LOG.info("START: #{$PROGRAM_NAME} #{ARGV.join(' ')}")
  end

  def initialize(argv)
    log_init()

    one_commit = argv.include?(ONE_COMMIT)
    argv.delete(ONE_COMMIT) if one_commit

    same_mount = argv.include?(SAME_MOUNT)
    argv.delete(SAME_MOUNT) if same_mount

    mode = argv.shift
    args = argv

    begin
      case mode

      when ALL
        fail ParamsError.new unless args.count < 2 && (!args.first || args.first.to_i > 0)
        target_dirs = [Downloader.download_to_directory_and_link(page: args.first.to_i)]

      when BACK
        fail ParamsError.new unless args.count == 1 && args.first.to_i > 0
        target_dirs = [Downloader.download_to_directory_and_link(days: args.first.to_i)]

      when DIRS
        fail ParamsError.new if args.empty? || notargs.map { |dir| File.directory?(dir) }.all?
        target_dirs = args

      when FILES
        fail ParamsError.new if args.empty?
        files = args

      when IDS
        fail ParamsError.new unless args.count >= 1
        target_dirs = [Downloader.download_to_directory_and_link(ids: args)]

      else
        fail ParamsError.new
      end
    rescue ParamsError
      abort usage_message()
    end

    files ||= target_dirs.map do |target_dir|
      Dir.entries(target_dir)
      .reject { |file_name| ['.', '..'].include?(file_name) }
      .map { |file_name| "#{target_dir}/#{file_name}" }
    end.flatten.sort

    @opts = {files: files, one_commit: one_commit, same_mount: same_mount}
  end

  def usage_message()
    <<-EOF.gsub(/^ {4}/, '')
      USAGE: #{File.basename($PROGRAM_NAME)} [#{ONE_COMMIT}] [#{SAME_MOUNT}]
             ( #{ALL} [PAGE] | #{BACK} DAYS
               | #{FILES} FILE ... | #{DIRS} DIR ... | #{IDS} ID ... )
        #{ONE_COMMIT}: Optionally, make just one commit at the end, rather than
          one commit per file.
        #{SAME_MOUNT}: Optionally, allow same mount point for the script and the
          solr index. This is what you want in development, but the default, to
          disallow this, would have stopped me from running out of disk many times.
        #{ALL}: Download, clean, and ingest all PBCore from the AMS. Optionally,
          supply a results page to begin with.
        #{BACK}: Download, clean, and ingest only those records updated in the
          last N days. (I don't trust the underlying API, so give yourself a
          buffer if you use this for daily updates.)
        #{FILES}: Clean and ingest the given files.
        #{DIRS}: Clean and ingest the given directories. (While "#{FILES} dir/*"
          could suffice in many cases, for large directories it might not work,
          and this is easier than xargs.)
        #{IDS}: Download, clean, and ingest records with the given IDs. Will
          usually be used in conjunction with #{ONE_COMMIT}, rather than
          committing after each record.
      EOF
  end

  def process()
    fails = { read: [], clean: [], validate: [], add: [], other: [] }
    success = []
    ingester = PBCoreIngester.new(same_mount: @opts[:same_mount])

    @opts[:files].each do |path|
      begin
        ingester.ingest(path: path, one_commit: @opts[:one_commit])
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
        $LOG.info("Successfully added '#{path}' #{'but not committed' if @opts[:one_commit]}")
        success << path
      end
    end

    if @opts[:one_commit]
      $LOG.info('Starting one big commit...')
      ingester.commit
      $LOG.info('Finished one big commit.')
    end

    # TODO: Investigate whether optimization is worth it. Requires a lot of disk and time.
    # puts 'Ingest complete; Begin optimization...'
    # ingester.optimize

    $LOG.info('SUMMARY')

    fails.each {|type, list|
      $LOG.warn("#{list.count} failed to #{type}:\n#{list.join("\n")}") unless list.empty?
    }
    $LOG.info("#{success.count} succeeded")

    $LOG.info('DONE')
  end
end

if __FILE__ == $PROGRAM_NAME
  DownloadCleanIngest.new(ARGV).process()
end

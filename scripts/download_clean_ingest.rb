require ::File.expand_path('../../config/environment', __FILE__)
require_relative 'lib/cleaner'
require_relative 'lib/pb_core_ingester'

class Exception
  def short
    message + "\n" + backtrace[0..2].join("\n")
  end
end

class ParamsError < StandardError
end

class DownloadCleanIngest
  def const_init(name)
    const_name = name.upcase.tr('-', '_')
    flag_name = "--#{name}"
    begin
      # to avoid "warning: already initialized constant" in tests.
      DownloadCleanIngest.const_get(const_name)
    rescue NameError
      DownloadCleanIngest.const_set(const_name, flag_name)
    end
  end

  def initialize(argv)
    orig = argv.clone

    %w(all back query dirs files ids id-files exhibits).each do |name|
      const_init(name)
    end

    %w(batch-commit stdout-log just-reindex leave-files).each do |name|
      flag_name = const_init(name)
      variable_name = "@is_#{name.tr('-', '_')}"
      instance_variable_set(variable_name, argv.include?(flag_name))
      argv.delete(flag_name)
    end

    mode = argv.shift
    args = argv

    unrecognized_flags = args.select { |arg| arg =~ /^-/ }
    raise("Unrecognized flags: #{unrecognized_flags.join(', ')}") unless unrecognized_flags.empty?

    log_init(orig)
    $LOG.info("START: Process ##{Process.pid}: #{__FILE__} #{orig.join(' ')}")

    begin
      case mode

      when DIRS
        raise ParamsError.new if args.empty? || args.map { |dir| !File.directory?(dir) }.any?
        target_dirs = args

      when FILES
        raise ParamsError.new if args.empty?
        @files = args

      else
        raise ParamsError.new
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
    sanitized_argv = argv.grep(/--/).map { |a| a.sub('--', '') }.join('-')
    log_file_name = if @is_stdout_log
                      $stdout
                    else
                      Rails.root + "log/ingest-#{sanitized_argv}.log"
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
               [#{BATCH_COMMIT}] [#{STDOUT_LOG}] [#{LEAVE_FILES}]
                 | #{FILES} FILE ... | #{DIRS} DIR ...

      boolean flags:
        #{BATCH_COMMIT}: Optionally, make just one commit at the end, rather than
          one commit per file.
        #{STDOUT_LOG}: Optionally, log to stdout, rather than a log file.
        #{LEAVE_FILES}: Leave pbcore files in place.

      mutually exclusive modes:
        #{FILES}: Clean and ingest the given files.
        #{DIRS}: Clean and ingest the given directories. (While "#{FILES} dir/*"
          could suffice in many cases, for large directories it might not work,
          and this is easier than xargs.)
      EOF
  end

  def process
    ingester = PBCoreIngester.new

    @files.each do |path|
      begin
        success_count_before = ingester.success_count
        error_count_before = ingester.errors.values.flatten.count
        ingester.ingest(path: path, is_batch_commit: @is_batch_commit, is_leave_files: @is_leave_files)
        success_count_after = ingester.success_count
        error_count_after = ingester.errors.values.flatten.count
        $LOG.info("Processed '#{path}' #{'but not committed' if @is_batch_commit}")
        $LOG.info("success: #{success_count_after - success_count_before}; " \
          "error: #{error_count_after - error_count_before}")
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

    errors = ingester.errors.sort # So related errors are together
    error_count = errors.map { |pair| pair[1] }.flatten.count
    success_count = ingester.success_count
    total_count = error_count + success_count

    $LOG.info('SUMMARY: DETAIL')
    errors.each do |type, list|
      $LOG.warn("#{list.count} #{type} errors:\n#{list.join("\n")}")
    end

    $LOG.info('SUMMARY: STATS')
    $LOG.info('(Look just above for details on each error.)')
    errors.each do |type, list|
      $LOG.warn("#{list.count} (#{percent(list.count, total_count)}%) #{type}")
    end
    $LOG.info("#{success_count} (#{percent(success_count, total_count)}%) succeeded")

    $LOG.info('DONE')
  end

  def percent(part, whole)
    (100.0 * part / whole).round(1)
  end
end

DownloadCleanIngest.new(ARGV).process if __FILE__ == $PROGRAM_NAME

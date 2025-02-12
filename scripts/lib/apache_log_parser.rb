require 'time'

Object.send(:remove_const, :ApacheLogParser) if defined? ApacheLogParser
Object.send(:remove_const, :"ApacheLogParser::Entry") if defined? ApacheLogParser::Entry
Object.send(:remove_const, :BadBotConfigLines) if defined? BadBotConfigLines

class ApacheLogParser
  attr_reader :files

  def initialize(files: [])
    @files = Array(files)
  end

  def entries
    @entries ||= files.map do |file|
      File.readlines(file, chomp: true).map do |line|
        Entry.new(line)
      end
    end.flatten
  end

  def filter!(&block)
    @entries = entries.select(&block)
  end

  def count_by(&block)
    entries.group_by(&block).map do |k, entries|
      [k, entries.count]
    end.to_h.sort_by do |_k, count|
      count
    end.reverse.to_h
  end

  def count_by_ip(octets: 4)
    count_by do |entry|
      entry.ip(octets: octets)
    end
  end

  class Entry
    QUOTED_REGEX = /"([^"]*)"/
    BRACKETED_REGEX = /\[([^\[\]]*)\]/

    attr_reader :line
    def initialize(line)
      @line = line
    end

    def ip(octets: 4)
      bare_vals[0].split('.')[0...octets].join('.')
    end

    def client_id
      bare_vals[1]
    end

    def http_auth_user
      bare_vals[2]
    end

    def timestamp
      DateTime.strptime(bracketed_vals[0], '%d/%b/%Y:%H:%M:%S %z')
    end

    def request
      quoted_vals[0]
    end

    def request_method
      request.split(/\s/).to_a[0]
    end

    def request_uri
      request.split(/\s/).to_a[1]
    end

    def request_protocol
      request.split(/\s/).to_a[2]
    end

    def status
      bare_vals[3].to_i
    end

    def response_size
      bare_vals[4].to_i
    end

    def referer
      quoted_vals[1]
    end

    def user_agent
      quoted_vals[2]
    end

    def quoted_vals
      line.scan(QUOTED_REGEX).to_a.flatten
    end

    def bracketed_vals
      line.scan(BRACKETED_REGEX).to_a.flatten
    end

    def bare_vals
      line.gsub(BRACKETED_REGEX, '').gsub(QUOTED_REGEX, '').split(' ')
    end
  end
end

class BadBotConfigLines
  attr_reader :ips, :indent

  def initialize(ips: [], indent: '  ')
    @ips = Array(ips)
    @indent = indent
  end

  def to_s
    indent + ips.map do |ip|
      ip += '.' if ip.count('.') < 3
      ip = ip.gsub('.', '\.')
      "SetEnvIfNoCase Remote_Addr \"^#{ip}\" bad_bot"
    end.join("\n#{indent}")
  end
end


begin
  if $PROGRAM_NAME == __FILE__
    puts "Parsing Apache Log on " + DateTime.now.new_offset("-05:00").strftime('%Y-%m-%d %I:%M:%S %P')

    # Grab parameters form command line args
    glob = ARGV[0].to_s
    octets = (ARGV[1] || 2).to_i
    count = (ARGV[2] || 25).to_i


    # Get thre files, raise if none found
    raise "Pass in a glob of Apache log files to parse" if glob.empty?
    files = Dir.glob(glob)
    raise "No files found in '#{ARGV[0]}'" if files.empty?

    raise "Octests (2nd argument) must be a number between 1 and 4" unless (1..4).include?(octets)
    raise "Count (3rd argument) must be a number greater than 0" unless count > 0

    p = ApacheLogParser.new(files: files)

    bad_bots = p.entries.select do |e|
      e.ip != '::1'
    end.select do |e|
      e.request_uri =~ /catalog\?/
    end.group_by do |e|
      e.ip.split('.').first(octets).join('.')
    end.map do |ip, entries|
      [ip, entries.count]
    end.sort_by do |_ip, count|
      count
    end.reverse.first(count).to_h

    # Output the lines for bad bot configuration
    puts "Worst #{bad_bots.count} Offenders:\n#{bad_bots.map { |k, v| "#{k}: #{v}" }.join("\n")}\n\n"
    puts "Apache config to flag them:\n\n"
    puts BadBotConfigLines.new(ips: bad_bots.keys)
  end
rescue => e
  if ['true', '1', 'yes', 'y'].include?(ENV['DEBUG'].to_s.downcase)
    puts "#{e.class}: #{e.message}"
    puts e.backtrace.join("\n")
  else
    puts e.message
    exit 1
  end
end
require 'yaml'
require 'curb'
require 'json'
require 'sony_ci_api/sony_ci_admin'

if __FILE__ == $PROGRAM_NAME
  args = begin
    Hash[ARGV.slice_before { |a| a.match(/^--/) }.to_a.map { |a| [a[0].gsub(/^--/, ''), a[1..-1]] }]
  rescue
    {}
  end

  ci = SonyCiAdmin.new(
    # verbose: true,
    credentials_path: File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml')

  begin
    case args.keys.sort
    when %w(log up)
      raise ArgumentError.new if args['log'].empty? || args['up'].empty?
      args['up'].each { |path| ci.upload(path, args['log'].first) }

    when %w(down)
      raise ArgumentError.new if args['down'].empty?
      args['down'].each { |id| puts ci.download(id) }

    when %w(list)
      raise ArgumentError.new if args['list'].empty?
      ci.each { |asset| puts "#{asset['name']}\t#{asset['id']}" }

    when %w(recheck)
      raise ArgumentError.new if args['recheck'].empty?
      args['recheck'].each do |file|
        File.foreach(file) do |line|
          line.chomp!
          id = line.split("\t")[2]
          detail = ci.detail(id).to_s.tr("\n", ' ')
          puts line + "\t" + detail
        end
      end
    else
      raise ArgumentError.new
    end
  rescue ArgumentError
    abort 'Usage: --up GLOB --log LOG_FILE | --down ID | --list | --recheck LOG_FILE'
  end
end

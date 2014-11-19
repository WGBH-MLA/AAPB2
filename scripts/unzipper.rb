# Samples contents of zip files.

require 'zip'

class Unzipper
  include Enumerable
  
  def initialize(skip=100, blob='/Volumes/dept/MLA/American_Archive/Website/AMS/ams_pbcore_export_zipped/*.zip', log=STDERR)
    raise "'skip' must be integer > 0, not #{skip}" unless skip.to_i > 0
    @skip = skip.to_i
    @blob = blob
    @log = log
  end
  
  def each
    count = 0
    Dir[@blob].each do |zip_path|
      zip_base = File.basename zip_path
      @log.puts "\nunzipping #{zip_base}..."

      Zip::File.open(zip_path) do |zip_file|
        zip_file.each do |entry|
          if count % @skip == 0 && entry.name.match(/\.xml$/)
            @log.puts "\n#{count}: reading #{entry.name} from #{zip_base}"
            content = entry.get_input_stream.read
            if content.match(/^<\?[^>]*>\s*<premis/)
              @log.puts "#{entry.name} is premis xml. skipping."
            else
              yield content
            end
          else
            @log.print '.'
          end
          count += 1
        end
      end
    end
    raise "Expected at least one zipped file in #{@blob}" if count == 0
  end
  
end

if __FILE__ == $0
  if ARGV.count != 1
    abort "Expects one argument, not #{ARGV.count}"
  end
  
  unzipper = Unzipper.new(ARGV[0])
  unzipper.each do |content|
    puts content
  end
end

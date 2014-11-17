# sample zip files, and output all to STDOUT.

require 'zip'
require 'byebug'

if ARGV.count != 1 || !(ARGV[0].to_i > 0)
  abort 'Requires one argument: sample interval. "1" includes every record, "2" ever other record, ...'
else
  skip = ARGV[0].to_i
end
count = 0
zip_blob = '/Volumes/dept/MLA/American_Archive/Website/AMS/ams_pbcore_export_zipped/*.zip'

Dir[zip_blob].each do |zip_path|
  zip_base = File.basename zip_path
  STDERR.puts "unzipping #{zip_base}..."
  
  Zip::File.open(zip_path) do |zip_file|
    zip_file.each do |entry|
      if count % skip == 0
        STDERR.print "\n#{count}: reading #{entry.name} from #{zip_base}\n"
        puts entry.get_input_stream.read
      else
        STDERR.print '.'
      end
      count += 1
    end
  end
  
  STDERR.puts
  
end

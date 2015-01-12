require 'net/http'
require 'pry'

class Downloader

  KEY = 'b5f3288f3c6b6274c3455ec16a2bb67a'
  # From docs at https://github.com/avpreserve/AMS/blob/master/documentation/ams-web-services.md
  # ie, this not sensitive.
  
  def initialize(digitized, start_page=0, stop_page=nil)
    @digitized = digitized
    @start_page = start_page
    @stop_page = stop_page
    @log = STDERR
  end
  
  def download_to_directory(directory_path)
    download do |content,digitized,page|
      path = "#{directory_path}/download-#{Time.now.strftime('%v')}-#{digitized}-#{page}.xml"
      File.write(path, content)
    end
  end
  
  def download
    page = @start_page
    while !@stop_page || page < @stop_page
      url = "https://ams.americanarchive.org/xml/pbcore/key/#{KEY}/digitized/#{@digitized}/page/#{page}"
      content = Net::HTTP.get(URI.parse(url))
      if content =~ /^<error>/
        @log << "Paged past end of results: page #{page}\n"
        return
      else
        @log << "Got page #{page}\n"
        yield(content, @digitized, page)
        page += 1
      end
    end
  end
  
end

if __FILE__ == $0
  digitized = ARGV[0]
  start_page = ARGV[1].to_i if ARGV[1]
  stop_page = ARGV[2].to_i if ARGV[2]
  
  Dir.chdir(File.dirname(File.dirname(__FILE__)))
  # TODO: what's a good idiom for this?
  # Dir.mkdir('tmp') rescue ''
  # Dir.mkdir('tmp/pbcore') rescue ''
  # Dir.mkdir('tmp/pbcore/download') rescue ''

  downloader = Downloader.new(digitized, start_page, stop_page)
  downloader.download_to_directory('tmp/pbcore/download')
end
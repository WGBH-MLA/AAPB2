require 'net/http'
require 'rexml/xpath'
require 'rexml/document'
require_relative 'uncollector'

class Downloader

  KEY = 'b5f3288f3c6b6274c3455ec16a2bb67a'
  # From docs at https://github.com/avpreserve/AMS/blob/master/documentation/ams-web-services.md
  # ie, this not sensitive.
  
  def initialize(since)
    @since = since
    since.match(/(\d{4})(\d{2})(\d{2})/).tap do |match|
      raise('USAGE: downloader.rb YYYYMMDD') unless match &&
        match[1].to_i < 3000 &&
        match[2].to_i.tap{|m| (1 <= m) && (m <= 12)} &&
        match[3].to_i.tap{|d| (1 <= d) && (d <= 31)}
    end
    @log = File.basename($0) == 'rspec' ? [] : STDOUT
  end
  
  def self.download_to_directory_and_link(padding = nil)
    since = padding ?
      (Time.now-padding*24*60*60).strftime('%Y%m%d') :
      20000101 # ie, beginning of time.
    Dir.chdir(File.dirname(File.dirname(__FILE__)))
    path = ['tmp','pbcore','download',"#{Time.now.strftime('%F_%T')}_since_#{since}"]
    path.each do |dir|
      Dir.mkdir(dir) rescue nil # may already exist
      Dir.chdir(dir)
    end

    downloader = Downloader.new(since)
    downloader.download_to_directory

    Dir.chdir('..')
    link_name = 'LATEST'
    if File.exists?(link_name)
      if File.symlink?(link_name)
        File.unlink(link_name)
      else
        raise "Expected #{link_name} to be a link"
      end
    end
    File.symlink(path.last,link_name)
    return File.absolute_path(link_name)
  end
  
  def download_to_directory
    download do |collection|
      Uncollector::uncollect_string(collection).each do |pbcore|
        doc = REXML::Document.new(pbcore)
        id = REXML::XPath.match(doc, '/*/pbcoreIdentifier[@source="http://americanarchiveinventory.org"]').first.text
        name = "#{id.gsub('/','-')}.pbcore"
        File.write(name, pbcore)
        @log << "Wrote #{name}\n"
      end
    end
  end
  
  def download
    page = 1 # API is 1-indexed, but also returns page 1 results for page 0, so watch out.
    while true
      url = "https://ams.americanarchive.org/xml/pbcore/key/#{KEY}/modified_date/#{@since}/page/#{page}"
      @log << "Trying #{url}\n"
      content = Net::HTTP.get(URI.parse(url))
      if content =~ /^<error>/
        @log << "Paged past end of results: page #{page}\n"
        return
      else
        @log << "Got page #{page}\n"
        yield(content)
        page += 1
      end
    end
  end
  
end

if __FILE__ == $0
  abort 'No args' unless ARGV.empty?
  Downloader::download_to_directory_and_link
end
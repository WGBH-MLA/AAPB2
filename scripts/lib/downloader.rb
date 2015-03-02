require 'net/http'
require 'rexml/xpath'
require 'rexml/document'
require 'set'

class Downloader

  KEY = 'b5f3288f3c6b6274c3455ec16a2bb67a'
  # From docs at https://github.com/avpreserve/AMS/blob/master/documentation/ams-web-services.md
  # ie, this not sensitive.

  def initialize(since)
    @since = since
    since.match(/(\d{4})(\d{2})(\d{2})/).tap do |match|
      raise("Expected YYYYMMDD, not '#{since}'") unless match &&
        match[1].to_i < 3000 &&
        match[2].to_i.instance_eval{|m| (1 <= m) && (m <= 12)} &&
        match[3].to_i.instance_eval{|d| (1 <= d) && (d <= 31)}
    end
    @log = File.basename($0) == 'rspec' ? [] : STDOUT
  end

  def self.download_to_directory_and_link(args={})
    raise("Unexpected keys: #{args}") unless Set.new(args.keys).subset?(Set[:days, :page])
    args[:page] ||= 1 # API is 1-indexed, but also returns page 1 results for page 0.
    since = args[:days] ?
      (Time.now-args[:days]*24*60*60).strftime('%Y%m%d') :
      '20000101' # ie, beginning of time.
    Dir.chdir(File.dirname(File.dirname(File.dirname(__FILE__))))
    path = ['tmp','pbcore','download', #
      "#{Time.now.strftime('%F_%T')}_since_#{since}_starting_page_#{args[:page]}"]
    path.each do |dir|
      Dir.mkdir(dir) rescue nil # may already exist
      Dir.chdir(dir)
    end

    Dir.chdir('..')
    link_name = 'LATEST'
    if File.symlink?(link_name)
      File.unlink(link_name)
    end
    if File.exist?(link_name) # Does not return true for links! At least for me...
      raise "Did not expect '#{link_name}'"
    end
    File.symlink(path.last,link_name)

    Dir.chdir(link_name)
    downloader = Downloader.new(since)
    downloader.download_to_directory(args[:page])

    return Dir.pwd
  end

  def download_to_directory(page)
    download(page) do |collection,page|
      name = "page-#{page}.pbcore"
      File.write(name, collection)
      @log << "#{Time.now}\tWrote #{name}\n"
    end
  end

  def download(page)
    while true
      url = "https://ams.americanarchive.org/xml/pbcore/key/#{KEY}/modified_date/#{@since}/page/#{page}"
      content = nil
      while !content
        begin
          @log << "#{Time.now}\tTrying #{url}\n"
          content = Net::HTTP.get(URI.parse(url))
        rescue Net::ReadTimeout
          @log << "#{Time.now}\tTimeout. Retrying in 10...\n"
          sleep 10
        end
      end
      if content =~ /^<error>/
        @log << "#{Time.now}\tPaged past end of results: page #{page}\n"
        return
      else
        @log << "#{Time.now}\tGot page #{page}\n"
        yield(content,page)
        page += 1
      end
    end
  end

end

if __FILE__ == $0
  abort 'No args' unless ARGV.empty?
  Downloader::download_to_directory_and_link
end

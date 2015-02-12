require 'yaml'
require 'curb'
require 'json'
require_relative '../../app/models/ci_core'

class Ci < CiCore
  
  include Enumerable
  
  def upload(file_path, log_file)
    Uploader.new(self, file_path, log_file).upload
  end
  
  def list_names
    list.map{|item| item['name']} - ['Workspace'] # A self reference is present even in an empty workspace.
  end
  
  def list(limit=50, offset=0)
    Lister.new(self).list(limit, offset)
  end
  
  def each
    Lister.new(self).each{|asset| yield asset}
  end
  
  def delete(asset_id)
    Deleter.new(self).delete(asset_id)
  end
  
  def detail(asset_id)
    Detailer.new(self).detail(asset_id)
  end
  
  private
  
  class CiClient
    # This class hierarchy might be excessive, but it gives us:
    # - a single place for the `perform` method
    # - and an isolated container for related private methods
    
    def perform(curl, mime=nil)
      # TODO: Is this actually working?
      # curl.on_missing { |data| puts "4xx: #{data}" }
      # curl.on_failure { |data| puts "5xx: #{data}" }
      curl.verbose = @ci.verbose
      curl.headers['Authorization'] = "Bearer #{@ci.access_token}"
      curl.headers['Content-Type'] = mime if mime
      curl.perform
    end
  end
  
  class Detailer < CiClient
    
    def initialize(ci)
      @ci = ci
    end
    
    def detail(asset_id)
      curl = Curl::Easy.http_get("https:""//api.cimediacloud.com/assets/#{asset_id}") do |c|
        perform(c)
      end
      JSON.parse(curl.body_str)
    end
    
  end
  
  class Deleter < CiClient
    
    def initialize(ci)
      @ci = ci
    end
    
    def delete(asset_id)
      Curl::Easy.http_delete("https:""//api.cimediacloud.com/assets/#{asset_id}") do |c|
        perform(c)
      end
    end
    
  end
  
  class Lister < CiClient
    
    include Enumerable
    
    def initialize(ci)
      @ci = ci
    end
    
    def list(limit, offset)
      curl = Curl::Easy.http_get("https:""//api.cimediacloud.com/workspaces/#{@ci.workspace_id}/contents?limit=#{limit}&offset=#{offset}") do |c|
        perform(c)
      end
      JSON.parse(curl.body_str)['items']
    end
    
    def each
      limit = 5 # Small chunks so it's easy to spot windowing problems
      offset = 0
      while true do
        assets = list(limit, offset)
        break if assets.empty?
        assets.each{|asset| yield asset}
        offset += limit
      end
    end
    
  end
  
  class Uploader < CiClient
    
    def initialize(ci, path, log_path)
      @ci = ci
      @path = path
      @log_file = File.open(log_path, 'a')
    end
    
    def upload
      file = File.new(@path)
      if file.size > 5*1024*1024
        initiate_multipart_upload(file)
        do_multipart_upload_part(file)
        complete_multipart_upload
      else
        singlepart_upload(file)
      end

      row = [Time.now, File.basename(@path), @asset_id, 
        @ci.detail(@asset_id).to_s.gsub("\n",' ')]
      @log_file.write(row.join("\t")+"\n")
      @log_file.flush
      
      return @asset_id
    end
    
    private
    
    SINGLEPART_URI = 'https://io.cimediacloud.com/upload'
    MULTIPART_URI = 'https://io.cimediacloud.com/upload/multipart'
        
    def singlepart_upload(file)
      curl = "curl -s -XPOST '#{SINGLEPART_URI}'" +
        " -H 'Authorization: Bearer #{@ci.access_token}'" +
        " -F filename='@#{file.path}'" +
        " -F metadata=\"{'workspaceId': '#{@ci.workspace_id}'}\""
      body_str = `#{curl}`
      @asset_id = JSON.parse(body_str)['assetId']
      raise "Upload failed: #{body_str}" unless @asset_id
      # TODO: This shouldn't be hard, but it just hasn't worked for me.
#      params = {
#        File.basename(file) => file.read,
#        'metadata' => JSON.generate({})
#      }.map { |k,v| Curl::PostField.content(k,v) }
#      curl = Curl::Easy.http_post(SINGLEPART_URI, params) do |c|
#        c.multipart_form_post = true
#        perform(c)
#      end
    end
    
    def initiate_multipart_upload(file)
      params = JSON.generate({
        'name' => File.basename(file),
        'size' => file.size,
        'workspaceId' => @ci.workspace_id
      })
      curl = Curl::Easy.http_post(MULTIPART_URI, params) do |c|
        perform(c, 'application/json')
      end
      @asset_id = JSON.parse(curl.body_str)['assetId']
    end
    
    def do_multipart_upload_part(file)
      Curl::Easy.http_put("#{MULTIPART_URI}/#{@asset_id}/1", file.read) do |c|
        perform(c, 'application/octet-stream')
      end
    end

    def complete_multipart_upload
      Curl::Easy.http_post("#{MULTIPART_URI}/#{@asset_id}/complete") do |c|
        perform(c)
      end
    end
    
  end
  
end

if __FILE__ == $0
  args = Hash[ARGV.slice_before{|a| a.match /^--/}.to_a.map{|a| [a[0].gsub(/^--/,''),a[1..-1]]}] rescue {}
  
  ci = Ci.new(
    #verbose: true, 
    credentials_path: File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml')
  
  begin
    case args.keys.sort
      
    when ['log','up']
      raise ArgumentError.new if args['log'].empty? || args['up'].empty?
      args['up'].each{|path| ci.upload(path, args['log'].first)}
      
    when ['down']
      raise ArgumentError.new if args['down'].empty?
      args['down'].each{|id| puts ci.download(id)}
      
    when ['list']
      raise ArgumentError.new if !args['list'].empty?
      ci.each{|asset| puts "#{asset['name']}\t#{asset['id']}"}
      
    when ['recheck']
      raise ArgumentError.new if args['recheck'].empty?
      args['recheck'].each{|file| File.foreach(file){|line|
        line.chomp!
        id = line.split("\t")[2]
        detail = ci.detail(id).to_s.gsub("\n",' ')
        puts line + "\t" + detail
      }}
      
    else
      raise ArgumentError.new  
    end
  rescue ArgumentError
    abort 'Usage: --up GLOB --log LOG_FILE | --down ID | --list | --recheck LOG_FILE'
  end
  
end
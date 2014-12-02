require 'yaml'
require 'curb'
require 'json'

class Ci

  attr_reader :access_token
  attr_reader :verbose
  attr_reader :workspace_id
  
  def initialize(opts={})
    @verbose = opts[:verbose] ? true : false
    
    raise 'Credentials specified twice' if opts[:credentials_path] && opts[:credentials]
    raise 'No credentials given' if !opts[:credentials_path] && !opts[:credentials]
    credentials = opts[:credentials] || YAML.load_file(opts[:credentials_path])
    
    credentials.keys.sort.tap { |actual|
      expected = ['username', 'password', 'client_id', 'client_secret'].sort
      raise "Expected #{expected} in ci credentials, not #{actual}" if actual != expected
    }
    
    params = {
      'grant_type' => 'password',
      'client_id' => credentials['client_id'],
      'client_secret' => credentials['client_secret']
    }.map { |k,v| Curl::PostField.content(k,v) }

    curl = Curl::Easy.http_post('https://api.cimediacloud.com/oauth2/token', *params) do |c|
      c.verbose = @verbose
      c.http_auth_types = :basic
      c.username = credentials['username']
      c.password = credentials['password']
      c.perform
    end

    @access_token = JSON.parse(curl.body_str)['access_token']
  end
  
  def cd(workspace_id)
    @workspace_id = workspace_id
  end
  
  def upload(file_path)
    Uploader.new(self, file_path).upload
  end
  
  def download(file_path)
    Downloader.new(self, file_path).download
  end
  
  private
  
  class CiClient
    def perform(curl, mime=nil)
      # TODO: Is this actually working?
      curl.on_missing { |data| raise "4xx: #{data}" }
      curl.on_failure { |data| raise "5xx: #{data}" }
      curl.verbose = @ci.verbose
      curl.headers['Authorization'] = "Bearer #{@ci.access_token}"
      curl.headers['Content-Type'] = mime if mime
      curl.perform
    end
  end
  
  class Downloader < CiClient
    
    def initialize(ci, asset_id)
      @ci = ci
      @asset_id = asset_id
    end
    
    def download
      curl = Curl::Easy.http_get("https""://api.cimediacloud.com/assets/#{@asset_id}/download") do |c|
        perform(c)
      end
      puts curl.body_str
    end
    
  end
  
  class Uploader < CiClient
    
    def initialize(ci, path)
      @ci = ci
      @file = File.new(path)
    end
    
    def upload
      if @file.size > 5*1024*1024
        initiate_multipart_upload
        do_multipart_upload_part
        complete_multipart_upload
      else
        singlepart_upload
      end
    end
    
    private
    
    SINGLEPART_URI = 'https://io.cimediacloud.com/upload'
    MULTIPART_URI = 'https://io.cimediacloud.com/upload/multipart'
        
    def singlepart_upload
      abort 'TODO: Not working.'

      params = {
        File.basename(@file) => @file.read,
        'metadata' => JSON.generate({})
      }.map { |k,v| Curl::PostField.content(k,v) }
      curl = Curl::Easy.http_post(SINGLEPART_URI, params) do |c|
        #c.multipart_form_post = true
        perform(c, 'multipart/form-data')
        #perform(c, 'application/form-multidata')
      end
    end
    
    def initiate_multipart_upload
      params = JSON.generate({
        'name' => File.basename(@file),
        'size' => @file.size,
        'workspaceId' => @ci.workspace_id
      })
      curl = Curl::Easy.http_post(MULTIPART_URI, params) do |c|
        perform(c, 'application/json')
      end
      @asset_id = JSON.parse(curl.body_str)['assetId']
    end
    
    def do_multipart_upload_part
      Curl::Easy.http_put("#{MULTIPART_URI}/#{@asset_id}/1", @file.read) do |c|
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
  abort 'Usage: ci.rb --up FILE | ci.rb --down ID' unless ARGV.count == 2
  flag = ARGV.shift
  arg = ARGV.shift
  
  ci = Ci.new(
    verbose: true, 
    credentials_path: File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml')
  
  case flag
  when '--up'
    ci.cd('051303c1c1d24da7988128e6d2f56aa9')
    ci.upload(arg)
  when '--down'
    ci.download(arg)
  else
    abort "'#{flag}' is not recognized: use '--up' or '--down'"
  end
end
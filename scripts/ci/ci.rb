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
  
  private
  
  class Uploader
    
    def initialize(ci, path)
      @ci = ci
      @file = File.new(path)
      initiate_multipart_upload
    end
    
    def upload
      do_multipart_upload_part
      complete_multipart_upload
    end
    
    private
    
    def perform(curl)
      curl.verbose = @ci.verbose
      curl.headers['Authorization'] = "Bearer #{@ci.access_token}"
      curl.perform
    end
    
    MULTIPART_URI = 'https://io.cimediacloud.com/upload/multipart'
        
    def initiate_multipart_upload
      params = JSON.generate({
        'name' => File.basename(@file),
        'size' => @file.size,
        'workspaceId' => @ci.workspace_id
      })
      curl = Curl::Easy.http_post(MULTIPART_URI, params) do |c|
        c.headers['Content-Type'] = 'application/json'
        perform(c)
      end
      @asset_id = JSON.parse(curl.body_str)['assetId']
    end
    
    def do_multipart_upload_part
      Curl::Easy.http_put("#{MULTIPART_URI}/#{@asset_id}/1", @file.read) do |c|
        c.headers['Content-Type'] = 'application/octet-stream'
        perform(c)
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
  abort 'Expects one argument, the file to upload.' unless ARGV.count == 1
  ci = Ci.new(
    verbose: true, 
    credentials_path: File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml')
  ci.cd('051303c1c1d24da7988128e6d2f56aa9')
  ci.upload(ARGV[0])
end
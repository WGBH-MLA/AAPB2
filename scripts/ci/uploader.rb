require 'yaml'
require 'curb'
require 'json'
require 'pry'

abort 'Expects one argument, the file to upload.' unless ARGV.count == 1
file = File.new(ARGV[0])

def get_token()
  creds = YAML.load_file(File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml')
  expected = ['username', 'password', 'client_id', 'client_secret'].sort
  actual = creds.keys.sort
  raise "Expected #{expected} in ci.yml, not #{actual}" if actual != expected

  params = {
    'grant_type' => 'password',
    'client_id' => creds['client_id'],
    'client_secret' => creds['client_secret']
  }.map { |k,v| Curl::PostField.content(k,v) }

  curl = Curl::Easy.http_post('https://api.cimediacloud.com/oauth2/token', *params) do |c|
    c.verbose = true # Very helpful!
    c.http_auth_types = :basic
    c.username = creds['username']
    c.password = creds['password']
    c.perform
  end

  JSON.parse(curl.body_str)['access_token']
end

def initiate_upload(token,file)
  params = JSON.generate({
    'name' => File.basename(file),
    'size' => file.size
  })
  curl = Curl::Easy.http_post('https://io.cimediacloud.com/upload/multipart', params) do |c|
    c.verbose = true
    c.headers['Authorization'] = "Bearer #{token}"
    c.headers['Content-Type'] = 'application/json'
    c.perform
  end
  
  JSON.parse(curl.body_str)['assetId']
end

def upload_part(token,asset_id,file)
  binding.pry
  # Examples have PUT?
  curl = Curl::Easy.http_put("https://io.cimediacloud.com/upload/multipart/#{asset_id}/1", file.read) do |c|
    c.verbose = true
    c.headers['Authorization'] = "Bearer #{token}"
    c.headers['Content-Type'] = 'application/octet-stream'
    c.perform
  end
end

def complete(token, asset_id)
  # curl -XPOST -i "https://io.cimediacloud.com/upload/multipart/87adshry23lk320923/complete" \
  #  -H "Authorization: Bearer ACCESS_TOKEN"
  curl = Curl::Easy.http_post("https://io.cimediacloud.com/upload/multipart/#{asset_id}/complete") do |c|
    c.verbose = true
    c.headers['Authorization'] = "Bearer #{token}"
    c.perform
  end
end

token = get_token
asset_id = initiate_upload(token, file)
upload_part(token, asset_id, file)
complete(token, asset_id)



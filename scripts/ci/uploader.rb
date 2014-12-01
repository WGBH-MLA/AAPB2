require 'yaml'
require 'curb'
require 'json'

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
    #c.verbose = true # Very helpful!
    c.http_auth_types = :basic
    c.username = creds['username']
    c.password = creds['password']
    c.perform
  end

  JSON.parse(curl.body_str)['access_token']
end

puts get_token



# THIS WORKS:
#basic_auth_base64 = Base64.encode64("#{creds['username']}:#{creds['password']}").strip
#
#uri = 'https://api.cimediacloud.com/oauth2/token'
#auth_header = "Authorization: Basic #{basic_auth_base64}"
#content_header = "Content-Type: application/x-www-form-urlencoded"
#params = "grant_type=password&client_id=#{creds['client_id']}&client_secret=#{creds['client_secret']}"
#
#curl = "curl -XPOST -i '#{uri}' -H '#{auth_header}' -H '#{content_header}' -d '#{params}'"
#
#puts curl
#puts `#{curl}`
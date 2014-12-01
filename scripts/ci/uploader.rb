require 'yaml'
require 'base64'

creds = YAML.load_file(File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml')
base64 = Base64.encode64("#{creds['username']}:#{creds['password']}").strip

url = 'https://api.cimediacloud.com/oauth2/token'
auth_header = "Authorization: Basic #{base64}"
content_header = "Content-Type: application/x-www-form-urlencoded"
params = "grant_type=password&client_id=#{creds['client_id']}&client_secret=#{creds['client_secret']}"

curl = "curl -XPOST -i '#{url}' -H '#{auth_header}' -H '#{content_header}' -d '#{params}'"

puts curl
puts `#{curl}`
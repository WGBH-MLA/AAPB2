require 'yaml'
require 'base64'

creds = YAML.load_file(File.dirname(File.dirname(File.dirname(__FILE__))) + '/config/ci.yml')
base64 = Base64.encode64("#{creds['username']}:#{creds['password']}")
# TODO: get developer key

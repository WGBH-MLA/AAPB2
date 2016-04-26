require 'popuparchive'

creds = YAML.load_file(__dir__ + '/popup-oauth.yml')

module PopUpArchive
  class Client
    def list_collections
      resp = get('/collections')
      return resp.http_resp.body
    end
  end
end

client = PopUpArchive::Client.new(
  id: creds['id'],
  secret: creds['secret'],
  host: 'https://www.popuparchive.com/',
  debug: false
)

puts client.list_collections.to_json
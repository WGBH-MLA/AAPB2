require 'popuparchive'
require 'json'

fail('Expects one argument') unless ARGV.length == 1
dir = ARGV.shift
fail('Expects argument not to exist yet') if File::exists?(dir)
Dir.mkdir(dir)

creds = YAML.load_file(__dir__ + '/popup-oauth.yml')

module PopUpArchive
  class Client
    def list_collections
      get('/collections').http_resp.body
    end
#    def pp(s)
#      puts s
#    end
  end
end

client = PopUpArchive::Client.new(
  id: creds['id'],
  secret: creds['secret'],
  host: 'https://www.popuparchive.com/',
#  debug: true
)

client.list_collections.collections.each do |collection|
  puts "#{collection.title}: #{collection.id}"
  
  subdir = File.join(dir, collection.id.to_s)
  Dir.mkdir(subdir)
  
  collection.item_ids.each do |item_id|
    puts item_id
    entities = client.get_item(collection.id, item_id).entities
    File.write(
      File.join(subdir, "#{item_id}-entities.json"), 
      JSON.pretty_generate(entities))
  end
  
  puts
end
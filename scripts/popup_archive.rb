require 'popuparchive'
require 'json'

raise('Expects one argument') unless ARGV.length == 1
dir = ARGV.shift
raise('Expects argument not to exist yet') if File.exist?(dir)
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
    item = client.get_item(collection.id, item_id)
    puts "#{item.title}: #{item.id}"

    base = item.title.sub(%r{.*/}, '')
    File.write(
      File.join(subdir, "#{base}-entities.json"),
      JSON.pretty_generate(item.entities))
    raise('Expected exactly one audio file per item') unless item.audio_files.size == 1
    File.write(
      File.join(subdir, "#{base}-transcript.json"),
      JSON.pretty_generate(item.audio_files.first.transcript))
  end

  puts
end

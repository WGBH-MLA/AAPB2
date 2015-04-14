require 'set'
require 'curb'
require 'singleton'

class LinkChecker
  include Singleton

  FILENAME = File.join(File.dirname(__FILE__), '.link-check.txt')
  RE_IGNORES = [
    /^\/catalog\?/, # too many combos
    /^\/catalog\//, # redundant
    /^https?:/, # TODO: remote sites
    /#/, # TODO: anchors
    /^mailto:/,
    /^\/participating-orgs/ # skip for now because it is slow.
  ]
  
  def initialize()
    @checked = Set[]
    @needs_recheck = LinkChecker.needs_recheck?
  end
  
  def self.needs_recheck?
    return true unless File.exist?(FILENAME)
    if (Time.now - File.mtime(FILENAME)) / (60 * 60 * 24 * 7) > 1
      File.unlink(FILENAME)
      return true
    end
    false
  end
  
  def check(url)
    return if url == nil # Calling code might forget a special case for <a name='foo'>
    return if ENV['CI'] # don't run on Travis
    return unless @needs_recheck
    return if @checked.include?(url)
    return if RE_IGNORES.map { |ignore| ignore.match(url) }.any?
    @checked << url

     # TODO: remote URLs

    fail("relative links are trouble: #{url}") if /^[^\/]/.match(url)

    full_url = 'http://localhost:3000' + url
    curl = Curl::Easy.http_get(full_url)
    code = curl.response_code
    fail("Got #{code} from #{full_url}") unless code == 200

    puts "[link-checked: #{url}]"
    File.open(FILENAME, 'a') { |f| f.write("#{url}\n") }
  end
end

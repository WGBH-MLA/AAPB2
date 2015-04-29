require 'set'
require 'curb'
require 'singleton'

class LinkChecker
  include Singleton

  FILENAME = File.dirname(__FILE__) + '/.link-check.txt'
  RE_IGNORES = [
    /^\/catalog\?/, # too many combos
    /^\/catalog\//, # redundant: other tests load each fixture
    /#/, # TODO: anchors
    /^mailto:/,
    /^\/participating-orgs/ # skip for now because it is slow and low benefit
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

    full_url = case url
               when /^https?:/
                 url
               when /^[^\/]/
                 fail("relative links are trouble: #{url}")
               else
                 'http://localhost:3000' + url
               end

    curl = Curl::Easy.new
    curl.url = full_url
    curl.follow_location = true
    curl.max_redirects = 1
    curl.http_get
    
    code = curl.response_code
    fail("Got #{code} from #{full_url} instead of 200") unless code == 200

    puts "[PASS: #{url}]"
    File.open(FILENAME, 'a') { |f| f.write("PASS: #{url}\n") }
  rescue => e
    puts "[FAIL: #{url}]"
    File.open(FILENAME, 'a') { |f| f.write("FAIL: #{url}\n") }
    throw(e)
  end    
end

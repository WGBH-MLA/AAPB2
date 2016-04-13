require 'set'
require 'curb'
require 'singleton'

class LinkChecker
  include Singleton

  REPORT_FILE = __dir__ + '/link-check-report.txt'
  IGNORE_FILE = __dir__ + '/link-check-ignore.txt'
  RE_IGNORES = [
    /^\/catalog\?/, # too many combos
    /^\/catalog\//, # redundant: other tests load each fixture
    /^#/, # TODO: anchors
    /^mailto:/
  ]

  def initialize
    @checked = Set.new(File.readlines(IGNORE_FILE).map(&:strip))
    File.unlink(REPORT_FILE) if File.exist?(REPORT_FILE)
  end

  def check?(url)
    return true if url.nil?
    url.gsub!(/#.*/, '') # Checking page content for anchor is a hassle.
    return true if url.empty?
    return true if @checked.include?(url)
    return true if RE_IGNORES.map { |ignore| ignore.match(url) }.any?
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

    report('PASS', url)
    true
  rescue => e
    report("FAIL #{e}", url)
    false
  end

  def report(status, url)
    puts "[#{status} #{url}]" # This gives context which is missing in the report.
    File.open(REPORT_FILE, 'a') { |f| f.write("#{status}: #{url}\n") }
  end
end

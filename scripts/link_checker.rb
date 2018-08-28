require 'csv'
require 'rest_client'
require 'nokogiri'

require 'set'
require 'curb'
require 'singleton'

class LinkChecker
  include Singleton

  REPORT_FILE = __dir__ + '/link-check-report.txt'
  IGNORE_FILE = 'spec/support/link-check-ignore.txt'
  RE_IGNORES = [
    /^\/catalog\?/, # too many combos
    /^\/catalog\//, # redundant: other tests load each fixture
    /^#/, # TODO: anchors
    /^mailto:/
  ].freeze

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
                 raise("relative links are trouble: #{url}")
               else
                 'http://localhost:3000' + url
               end

    curl = Curl::Easy.new
    curl.url = full_url
    curl.follow_location = true
    curl.max_redirects = 1
    curl.useragent = 'Ruby/Curb'
    # Avoid "Peer certificate cannot be authenticated with given CA
    # certificates" error on Travis CI.
    curl.http_get

    code = curl.response_code
    raise("Got #{code} from #{full_url} instead of 200") unless code == 200

    report('PASS', url)
    true
  rescue Curl::Err::SSLCACertificateError
    # For some reason, Travis's version of curl get's hung up on this error.
    # We don't care about certs right here though, so just pass it.
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

CSV.open('linkcheckresult.csv', 'w') do |csv|

	CSV.foreach('scripts/link_directory.csv') do |row|
		this_url = row.first

		full_url = if this_url.start_with?('/')
			%(http://localhost:3000#{this_url})
		else
			this_url
		end

		puts this_url
		add = [full_url]
		puts full_url

		doc = Nokogiri::HTML( RestClient.get( full_url ).body )
		links = doc.css('a')
		all_urls = links.map {|link| link.attribute('href').to_s}.uniq.sort.delete_if {|href| href.empty?}
	  bad_urls = all_urls.reject do |url|
	    LinkChecker.instance.check?(url)
	  end
		
		if bad_urls && bad_urls.count > 0
			puts %(Found BADLINSK: #{bad_urls})

			add += bad_urls
		end

		csv << add
		puts "added #{add.count - 1}"
	end

end

puts "Wrote results."
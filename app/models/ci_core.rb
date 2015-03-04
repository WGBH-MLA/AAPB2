require 'yaml'
require 'curb'
require 'json'

class CiCore
  attr_reader :access_token
  attr_reader :verbose
  attr_reader :workspace_id

  def initialize(opts={}) # rubocop:disable Metrics/PerceivedComplexity
    unrecognized_opts = opts.keys - [:verbose, :credentials_path, :credentials]
    fail "Unrecognized options #{unrecognized_opts}" unless unrecognized_opts == []

    @verbose = opts[:verbose] ? true : false

    fail 'Credentials specified twice' if opts[:credentials_path] && opts[:credentials]
    fail 'No credentials given' if !opts[:credentials_path] && !opts[:credentials]
    credentials = opts[:credentials] || YAML.load_file(opts[:credentials_path])

    credentials.keys.sort.tap do |actual|
      expected = ['username', 'password', 'client_id', 'client_secret', 'workspace_id'].sort
      fail "Expected #{expected} in ci credentials, not #{actual}" if actual != expected
    end

    params = {
      'grant_type' => 'password',
      'client_id' => credentials['client_id'],
      'client_secret' => credentials['client_secret']
    }.map { |k, v| Curl::PostField.content(k, v) }

    curl = Curl::Easy.http_post('https://api.cimediacloud.com/oauth2/token', *params) do |c|
      c.verbose = @verbose
      c.http_auth_types = :basic
      c.username = credentials['username']
      c.password = credentials['password']
      # c.on_missing { |curl, data| puts "4xx: #{data}" }
      # c.on_failure { |curl, data| puts "5xx: #{data}" }
      c.perform
    end

    @access_token = JSON.parse(curl.body_str)['access_token']
    fail 'OAuth failed' unless @access_token

    @workspace_id = credentials['workspace_id']
  end

  def download(asset_id)
    Downloader.new(self).download(asset_id)
  end

  class CiClient
    # This class hierarchy might be excessive, but it gives us:
    # - a single place for the `perform` method
    # - and an isolated container for related private methods

    def perform(curl, mime=nil)
      # TODO: Is this actually working?
      # curl.on_missing { |data| puts "4xx: #{data}" }
      # curl.on_failure { |data| puts "5xx: #{data}" }
      curl.verbose = @ci.verbose
      curl.headers['Authorization'] = "Bearer #{@ci.access_token}"
      curl.headers['Content-Type'] = mime if mime
      curl.perform
    end
  end

  class Downloader < CiClient
    @@cache = {}

    def initialize(ci)
      @ci = ci
    end

    def download(asset_id)
      hit = @@cache[asset_id]
      if !hit || hit[:expires] < Time.now
        curl = Curl::Easy.http_get('https'"://api.cimediacloud.com/assets/#{asset_id}/download") do |c|
          perform(c)
        end
        url = JSON.parse(curl.body_str)['location']
        @@cache[asset_id] = { url: url, expires: Time.now + 3 * 60 * 60 }
      end
      @@cache[asset_id][:url]
    end
  end
end

require_relative "../app/helpers/id_helper"
require 'httparty'

class ExternalFile
  include IdHelper

  attr_reader :guid, :type, :external_url

  def initialize(type, guid, external_url)
    @type = type
    @guid = normalize_guid(guid)
    @external_url = external_url
  end

  def file_present?(force_check: false)
    Rails.cache.delete(cache_key) if force_check
    Rails.cache.fetch(cache_key) do
      # cache our success
      head_file
    end
  end

  # TODO: cache this too
  def file_content

    require 'benchmark'
    times = {}
    times['ExternalFile#file_content'] = Benchmark.realtime do
      if file_present?
        @file_content ||= begin
          HTTParty.get(external_url).body
        rescue Errno::ECONNREFUSED, SocketError
          nil
        end
      end
    end

    Rails.logger.warn "\n\nBenchmark times:\n#{times.map{|k,v| "#{k}: #{v}"}.join("\n")}\n\n"
    return @file_content
  end

  def head_file
    response = HTTParty.head(external_url)
    response && response.code == 200
  rescue => error
    # Log the error, return false, but don't fail.
    Rails.logger.error("#{error.class}: #{error.message}")
    false
  end

  def cache_key
    "#{type}/#{guid}"
  end
end

require_relative "../app/helpers/id_helper"

class ExternalFile
  include IdHelper

  def initialize(type, guid, external_url)
    @type = type
    @guid = normalize_guid(guid)
    @external_url = external_url
  end

  def file_present?
    Rails.cache.fetch(cache_key) do
      # cache our success

      response = HTTParty.head(@external_url)
      response && response.code == 200


      # url = URI.parse(@external_url)
      # response = nil
      # puts "Trying request for #{@guid} #{url.host}, #{url.port} #{url.path}"
      # Net::HTTP.start(url.host, url.port) do |http|
      #   response = http.request_head(url.path)
      #   puts " yes response was #{response}"
      # end
      # response && response.code == 200
    end
  end

  def file_content
    if file_present?
      @file_content ||= begin
        # open(@external_url).read
        HTTParty.get(@external_url).body
      rescue Errno::ECONNREFUSED
        nil
      end
    end
  end

  def cache_key
    "#{@type}/#{@guid}"
  end
end

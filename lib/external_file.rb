require_relative "../app/helpers/id_helper"

class ExternalFile
  include IdHelper

  def initialize(type, guid, external_url)
    @type = type
    @guid = normalize_guid(guid)
    @external_url = external_url
  end

  def file_present?(force_check: false)
    return head_file if force_check
    Rails.cache.fetch(cache_key) do
      # cache our success
      head_file
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

  def head_file
    begin
      response = HTTParty.head(@external_url)
      response && response.code == 200
    rescue Errno::ECONNREFUSED
      nil
    end
  end

  def cache_key
    "#{@type}/#{@guid}"
  end
end

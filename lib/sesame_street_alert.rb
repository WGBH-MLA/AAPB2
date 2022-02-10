require_relative '../app/helpers/id_helper'

class SesameStreetAlert
  GUIDS_FILE = 'config/sesame_street_alert_guids.txt'.freeze

  class << self
    include IdHelper

    def guids
      @guids ||= if File.exist?(GUIDS_FILE)
                   File.readlines(GUIDS_FILE).map(&:chomp).map do |guid|
                     normalize_guid(guid)
                   end
                 else
                   []
                 end
    end

    def show?(guid)
      guid = normalize_guid(guid)
      guid_lookup[guid] || false
    end

    private

    # Creates a hash of the GUIDs for constant lookup time.
    def guid_lookup
      @guid_lookup ||= Hash[
        guids.map { |guid| [guid, true] }
      ]
    end
  end
end

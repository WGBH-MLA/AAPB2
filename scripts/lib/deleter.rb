require_relative '../../lib/rails_stub'
require_relative '../../app/models/exhibit'
require_relative '../lib/cleaner'
require_relative '../lib/pb_core_ingester'
require 'logger'
require 'rake'

class Deleter
  def initialize(ids)
    @ids = validate_ids(ids)
  end

  def delete
    ingester.delete_records(@ids)
  end

  private

  def validate_ids(ids)
    raise 'Invalid arguments for deleting AAPB records. Must be an Array of IDs.' unless ids.is_a? Array
    unless ids.all? { |id| AAPB.valid_id?(id) }
      puts "Got a non-GUID argument! That's not cool!"
      exit 1
    end
    ids
  end

  def ingester
    PBCoreIngester.new
  end
end

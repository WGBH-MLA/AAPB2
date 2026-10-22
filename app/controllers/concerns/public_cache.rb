# Only include in controllers whose output is identical for every visitor: the edge cache keys on URL alone.
module PublicCache
  extend ActiveSupport::Concern

  MAX_AGE = 5.minutes.to_i # matches the edge cache's maxExpiry

  included do
    after_action :cache_publicly
  end

  private

  def cache_publicly
    return unless (request.get? || request.head?) && response.status == 200
    expires_in MAX_AGE, public: true
  end
end

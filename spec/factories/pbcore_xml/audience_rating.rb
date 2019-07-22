require 'pbcore'

FactoryBot.define do
  factory :pbcore_audience_rating, class: PBCore::AudienceRating, parent: :pbcore_element do
    skip_create
    value { ['General', 'Empty-nester', 'K-7', 'Pre-teen'].sample }
    initialize_with { new(attributes) }
  end
end

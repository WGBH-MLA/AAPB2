require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_essence_track_type, class: PBCore::Instantiation::EssenceTrack::Type, parent: :pbcore_element do
    skip_create

    value { Faker::Hacker.abbreviation }

    initialize_with { new(attributes) }
  end
end
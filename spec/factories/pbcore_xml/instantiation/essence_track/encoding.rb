require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_essence_track_encoding, class: PBCore::Instantiation::EssenceTrack::Encoding, parent: :pbcore_element do
    skip_create

    value { Faker::Hacker.abbreviation }

    initialize_with { new(attributes) }
  end
end
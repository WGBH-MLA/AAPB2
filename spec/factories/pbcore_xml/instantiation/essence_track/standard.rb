require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_essence_track_standard, class: PBCore::Instantiation::EssenceTrack::Standard, parent: :pbcore_element do
    skip_create

    value { Faker::Hacker.abbreviation }

    initialize_with { new(attributes) }
  end
end
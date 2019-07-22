require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_essence_track_bit_depth, class: PBCore::Instantiation::EssenceTrack::BitDepth, parent: :pbcore_element do
    skip_create

    value { rand(10) }
    units_of_measure { Faker::Hacker.abbreviation }

    initialize_with { new(attributes) }
  end
end
require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_essence_track_data_rate, class: PBCore::Instantiation::EssenceTrack::DataRate, parent: :pbcore_element do
    skip_create

    value { rand(100).to_s }
    units_of_measure { Faker::Hacker.abbreviation }

    initialize_with { new(attributes) }
  end
end
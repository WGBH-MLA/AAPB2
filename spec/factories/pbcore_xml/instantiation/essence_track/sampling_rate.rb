require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_essence_track_sampling_rate, class: PBCore::Instantiation::EssenceTrack::SamplingRate, parent: :pbcore_element do
    skip_create

    value { rand(1.0..50.0).round(2).to_s }
    units_of_measure { Faker::Hacker.abbreviation }

    initialize_with { new(attributes) }
  end
end
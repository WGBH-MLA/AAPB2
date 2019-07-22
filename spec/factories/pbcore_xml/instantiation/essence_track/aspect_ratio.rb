require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_essence_track_aspect_ratio, class: PBCore::Instantiation::EssenceTrack::AspectRatio, parent: :pbcore_element do
    skip_create

    value { rand(10).to_s + ':' + rand(10).to_s }
    units_of_measure { Faker::Hacker.abbreviation }

    initialize_with { new(attributes) }
  end
end
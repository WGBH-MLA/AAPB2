require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_essence_track_frame_size, class: PBCore::Instantiation::EssenceTrack::FrameSize, parent: :pbcore_element do
    skip_create

    value { rand(1000).to_s + 'x' + rand(1000).to_s }
    units_of_measure { Faker::Hacker.abbreviation }

    initialize_with { new(attributes) }
  end
end
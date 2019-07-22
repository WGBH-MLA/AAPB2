require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_essence_track_playback_speed, class: PBCore::Instantiation::EssenceTrack::PlaybackSpeed, parent: :pbcore_element do
    skip_create

    value { rand(1..50).to_s }
    units_of_measure { ['RPM', 'IPS'].sample }

    initialize_with { new(attributes) }
  end
end

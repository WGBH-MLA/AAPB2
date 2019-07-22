require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_essence_track_duration, class: PBCore::Instantiation::EssenceTrack::Duration, parent: :pbcore_element do
    skip_create

    value { Time.now.strftime( "%H:%M:%S") }

    initialize_with { new(attributes) }
  end
end
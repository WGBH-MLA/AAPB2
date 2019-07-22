require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_essence_track_identifier, class: PBCore::Instantiation::EssenceTrack::Identifier, parent: :pbcore_element do
    skip_create

    value { Faker::IDNumber.valid }

    initialize_with { new(attributes) }
  end
end
require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_tracks, class: PBCore::Instantiation::Tracks, parent: :pbcore_element do
    skip_create

    value { Faker::Music.instrument }

    initialize_with { new(attributes) }
  end
end
require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_essence_track_annotation, class: PBCore::Instantiation::EssenceTrack::Annotation, parent: :pbcore_element do
    skip_create

    value { Faker::TvShows::Seinfeld.quote }
    type { Faker::TvShows::Seinfeld.character }

    initialize_with { new(attributes) }
  end
end

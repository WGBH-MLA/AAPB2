require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_document, class: PBCore::InstantiationDocument, parent: :pbcore_element do
    skip_create

    identifiers             { [ build(:pbcore_instantiation_identifier, :ams),
                                build(:pbcore_instantiation_identifier) ] }
    dates                   { [ build(:pbcore_instantiation_date), build(:pbcore_instantiation_date, :digitized) ] }
    dimensions              { [ build(:pbcore_instantiation_dimensions) ] }
    digital                 { build(:pbcore_instantiation_digital) }
    physical                { build(:pbcore_instantiation_physical) }
    standard                { build(:pbcore_instantiation_standard) }
    location                { build(:pbcore_instantiation_location) }
    media_type              { build(:pbcore_instantiation_media_type) }
    generations             { [ build(:pbcore_instantiation_generations) ] }
    time_starts             { [ build(:pbcore_instantiation_time_start) ] }
    duration                { build(:pbcore_instantiation_duration) }
    colors                  { build(:pbcore_instantiation_colors) }
    rights                  { [ build(:pbcore_instantiation_rights) ] }
    tracks                  { build(:pbcore_instantiation_tracks) }
    channel_configuration   { build(:pbcore_instantiation_channel_configuration) }
    alternative_modes       { build(:pbcore_instantiation_alternative_modes) }
    annotations             { [ build(:pbcore_instantiation_annotation, type: "Organization", value: "American Archive of Public Broadcasting") ] }

    initialize_with { new(attributes) }

    trait :media_info do
      physical          { }
      generations       { }
      essence_tracks    { [ build(:pbcore_instantiation_essence_track) ] }
    end
  end
end

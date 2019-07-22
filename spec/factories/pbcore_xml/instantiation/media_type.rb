require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_media_type, class: PBCore::Instantiation::MediaType, parent: :pbcore_element do
    skip_create

    value { [ "Moving Image", "Sound"].sample }

    initialize_with { new(attributes) }
  end
end
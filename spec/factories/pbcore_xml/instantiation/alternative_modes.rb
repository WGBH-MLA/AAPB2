require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_alternative_modes, class: PBCore::Instantiation::AlternativeModes, parent: :pbcore_element do
    skip_create

    value { Faker::Lorem.words.first }

    initialize_with { new(attributes) }
  end
end
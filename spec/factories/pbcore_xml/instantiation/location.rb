require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_location, class: PBCore::Instantiation::Location, parent: :pbcore_element do
    skip_create

    value { Faker::Address.city }

    initialize_with { new(attributes) }
  end
end
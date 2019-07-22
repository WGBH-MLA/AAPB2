require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_physical, class: PBCore::Instantiation::Physical, parent: :pbcore_element do
    skip_create

    value { Faker::Hacker.noun }

    initialize_with { new(attributes) }
  end
end
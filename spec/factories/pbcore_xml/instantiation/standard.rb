require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_standard, class: PBCore::Instantiation::Standard, parent: :pbcore_element do
    skip_create

    profile { Faker::Hacker.noun }
    value { Faker::Hacker.noun }

    initialize_with { new(attributes) }
  end
end
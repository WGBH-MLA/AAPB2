require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_digital, class: PBCore::Instantiation::Digital, parent: :pbcore_element do
    skip_create

    value { Faker::Hacker.noun }

    initialize_with { new(attributes) }
  end
end

require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_identifier, class: PBCore::Instantiation::Identifier, parent: :pbcore_element do
    skip_create

    source { Faker::Company.name }
    value { Faker::IDNumber.valid }

    trait :ams do
      source { "ams" }
      value { "cpb-blah-blah-blah" }
    end

    initialize_with { new(attributes) }
  end
end
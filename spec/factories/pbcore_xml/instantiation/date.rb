require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_date, class: PBCore::Instantiation::Date, parent: :pbcore_element do
    skip_create

    type { Faker::Types.rb_string }
    value { Faker::Date.backward(5000) }

    trait :digitized do
      type { "Digitized" }
    end

    initialize_with { new(attributes) }
  end
end

require 'pbcore'
require 'faker'

FactoryBot.define do
  factory :pbcore_annotation, class: PBCore::Annotation, parent: :pbcore_element do
    skip_create
    value { Faker::Quote.famous_last_words }

    trait :level_of_user_access_on_location do
      annotationType { 'Level Of User Access' }
      value { 'On Location' }
    end

    initialize_with { new(attributes) }
  end
end

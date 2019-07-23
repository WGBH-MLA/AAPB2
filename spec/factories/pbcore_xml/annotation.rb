require 'pbcore'
require 'faker'

FactoryBot.define do
  factory :pbcore_annotation, class: PBCore::Annotation, parent: :pbcore_element do
    skip_create
    value { Faker::Quote.famous_last_words }

    trait :level_of_user_access do
      type { 'Level Of User Access' }
    end
    trait :on_location do
      value { 'On Location' }
    end

    trait :online_reading_room do
      value { 'On Location' }
    end

    initialize_with { new(attributes) }
  end
end

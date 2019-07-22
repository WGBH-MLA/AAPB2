require 'pbcore'

FactoryBot.define do
  factory :pbcore_rights_summary, class: PBCore::RightsSummary, parent: :pbcore_element do
    skip_create

    trait :summary do
      rights_summary { PBCore::RightsSummary::RightsSummary.new(value: Faker::GreekPhilosophers.quote) }
    end

    trait :link do
      rights_link { PBCore::RightsSummary::RightsLink.new(value: Faker::Internet.url )}
    end

    initialize_with { new(attributes) }
  end
end

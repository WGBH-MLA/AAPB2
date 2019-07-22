require 'pbcore'

FactoryBot.define do
  factory :pbcore_genre, class: PBCore::Genre, parent: :pbcore_element do
    skip_create
    value { ['Documentary', 'Game Show', 'Performance in a Studio',
             'Performance for a Live Audience', 'Magazine', 'Promo'].sample }
    initialize_with { new(attributes) }

    trait :topic do
      value { Faker::Book.genre }
      source { "AAPB Topical Genre" }
    end
  end
end

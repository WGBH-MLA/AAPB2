require 'pbcore'
require 'faker'

FactoryBot.define do
  factory :pbcore_title, class: PBCore::Title, parent: :pbcore_element do
    skip_create

    value { "#{Faker::Book.title} #{Faker::Hipster.sentence}" }

    initialize_with { new(attributes) }
  end
end

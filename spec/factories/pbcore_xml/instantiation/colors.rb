require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_colors, class: PBCore::Instantiation::Colors, parent: :pbcore_element do
    skip_create

    value { Faker::Color.color_name }

    initialize_with { new(attributes) }
  end
end
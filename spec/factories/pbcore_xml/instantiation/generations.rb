require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_generations, class: PBCore::Instantiation::Generations, parent: :pbcore_element do
    skip_create

    value { [ 'Proxy', 'Mezzanine', 'Master', 'Preservation Master' ].sample }

    initialize_with { new(attributes) }
  end
end
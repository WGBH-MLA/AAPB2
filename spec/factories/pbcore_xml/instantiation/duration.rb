require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_duration, class: PBCore::Instantiation::Duration, parent: :pbcore_element do
    skip_create

    value { Time.now.strftime("%H:%M:%S") }

    initialize_with { new(attributes) }
  end
end
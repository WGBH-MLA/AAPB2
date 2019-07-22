require 'pbcore'

FactoryBot.define do
  factory :pbcore_instantiation_time_start, class: PBCore::Instantiation::TimeStart, parent: :pbcore_element do
    skip_create

    value { Time.now.strftime("%H:%M:%S") }

    initialize_with { new(attributes) }
  end
end
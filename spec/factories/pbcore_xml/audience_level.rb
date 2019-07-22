require 'pbcore'

FactoryBot.define do
  factory :pbcore_audience_level, class: PBCore::AudienceLevel, parent: :pbcore_element do
    skip_create
    value { ['G', 'PG', 'R', 'PG-13', 'NC-17'].sample }
    initialize_with { new(attributes) }
  end
end

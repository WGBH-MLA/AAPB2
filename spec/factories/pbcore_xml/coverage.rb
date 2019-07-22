require 'pbcore'

FactoryBot.define do
  factory :pbcore_coverage, class: PBCore::Coverage, parent: :pbcore_element do
    skip_create
    trait :spatial do
      coverage { PBCore::Coverage::Coverage.new(source: "latitude, longitude",
                                                value: "#{Faker::Address.latitude}, #{Faker::Address.longitude}") }
      type { PBCore::Coverage::Type.new(value: "Spatial") }
    end

    trait :temporal do
      coverage { PBCore::Coverage::Coverage.new(value: rand(1950..2018)) }
      type { PBCore::Coverage::Type.new(value: "Temporal") }
    end

    initialize_with { new(attributes) }
  end
end

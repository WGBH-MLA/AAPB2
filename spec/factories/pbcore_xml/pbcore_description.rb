require 'pbcore'

FactoryBot.define do
  factory :pbcore_description, class: PBCore::Description, parent: :pbcore_element do
    skip_create

    # Uses Digest to ensure the values are unique.
    value { Digest::SHA1.hexdigest([Time.now, rand].join)[0..10] + Faker::HitchhikersGuideToTheGalaxy.quote }

    initialize_with { new(attributes) }
  end
end

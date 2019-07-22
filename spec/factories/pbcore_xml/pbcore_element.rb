FactoryBot.define do
  factory :pbcore_element, class: PBCore::Element do
    skip_create

    trait :with_attributes do
      source { "value of source attribute" }
      ref { "value of ref attribute" }
      annotation { "value of annotation attribute" }
      version { "value of version attribute" }
    end

    initialize_with { new(attributes) }
  end
end

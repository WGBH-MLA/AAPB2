require 'pbcore'

FactoryBot.define do
  factory :pbcore_identifier, class: PBCore::Identifier, parent: :pbcore_element do
    skip_create

    trait :aapb do
      source { "http://americanarchiveinventory.org" }
      # Generates a random AAPB ID
      value { AMS::IdentifierService.mint }
    end

    trait :nola_code do
      source { "NOLA" }
      # 4 capital letters followed by number with leading zeros.
      value { ('A'..'Z').to_a.sample(4).join + '%04i' % rand(1..99) }
    end

    trait :eidr do
      source { "EIDR" }
      # Example: 10.5240/8795-EE4A-32C4-DC46-0F81-3
      value { (rand * 100).to_s.slice(0..6) + '/' +  Array.new(5) { '%04X' % rand(0x10000)  }.join('-') + '-' + ('A'..'Z').to_a.sample}
    end

    trait :local do
      source { "Local Identifier" }
      value { (('A'..'Z').to_a + (0..9).to_a).sample(rand(5..10)).join }
    end

    trait :sony_ci_video do
      source { "Sony Ci" }
      value { "e8eb953ef72244d8a711035754d36d5c" }
    end

    initialize_with { new(attributes) }
  end
end

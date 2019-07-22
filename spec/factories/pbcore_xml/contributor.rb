require 'pbcore'
require 'faker'

FactoryBot.define do
  factory :pbcore_contributor, class: PBCore::Contributor, parent: :pbcore_element do
    skip_create

    contributor { PBCore::Contributor::Contributor.new(value: Faker::FunnyName.two_word_name) }
    role { PBCore::Contributor::Role.new(value: Faker::Job.title)  }

    trait :with_portrayal do
      role { PBCore::Contributor::Role.new(value: Faker::Job.title, portrayal: Faker::TvShows::GameOfThrones.character)  }      
    end

    trait :with_affiliation do
      contributor { PBCore::Contributor::Contributor.new(value: Faker::FunnyName.two_word_name, affiliation: Faker::Company.name) }
    end

    initialize_with { new(attributes) }
  end
end

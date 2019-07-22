require 'pbcore'

FactoryBot.define do
  factory :pbcore_asset_type, class: PBCore::AssetType, parent: :pbcore_element do
    skip_create
    value { ['Program', 'Story', 'Moving image', 'Sound'].sample }
    initialize_with { new(attributes) }
  end
end

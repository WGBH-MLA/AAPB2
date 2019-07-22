require 'pbcore'

FactoryBot.define do
  factory :pbcore_description_document, class: PBCore::DescriptionDocument, parent: :pbcore_element do
    skip_create

    trait :full_aapb do
      # NOTE: Additional identifiers may be added with :other_identifiers.
      # See transient attribute below.
      identifiers       { [ build(:pbcore_identifier, :aapb) ] }
      audience_levels   { build_list(:pbcore_audience_level, rand(1..3)) }
      audience_ratings  { build_list(:pbcore_audience_rating, rand(1..3)) }
      asset_types       { build_list(:pbcore_asset_type, rand(1..3)) }
      annotations       { build_list(:pbcore_annotation, rand(1..3)) }
      subjects          { build_list(:pbcore_subject, rand(1..3)) }

      titles do
        [
          build_list(:pbcore_title, rand(1..3)),
          build_list(:pbcore_title, rand(1..3), type: 'Program'),
          build_list(:pbcore_title, rand(1..3), type: 'Episode'),
          build_list(:pbcore_title, rand(1..3), type: 'Segment'),
          build_list(:pbcore_title, rand(1..3), type: 'Promo'),
          build_list(:pbcore_title, rand(1..3), type: 'Clip'),
          build_list(:pbcore_title, rand(1..3), type: 'Raw Footage'),
          build(:pbcore_title, type: 'Episode Number', value: rand(1..500)),
        ].flatten
      end

      descriptions do
        [
          build_list(:pbcore_description, rand(1..3)),
          build_list(:pbcore_description, rand(1..3), type: 'Program'),
          build_list(:pbcore_description, rand(1..3), type: 'Episode'),
          build_list(:pbcore_description, rand(1..3), type: 'Segment'),
          build_list(:pbcore_description, rand(1..3), type: 'Promo'),
          build_list(:pbcore_description, rand(1..3), type: 'Clip'),
          build_list(:pbcore_description, rand(1..3), type: 'Raw Footage'),
        ].flatten
      end

      genres do
        [
          build_list(:pbcore_genre, rand(1..3)),
          build_list(:pbcore_genre, rand(1..3), :topic)
        ].flatten
      end

      coverages do
        [
          build(:pbcore_coverage, :spatial),
          build(:pbcore_coverage, :temporal)
        ]
      end

      rights_summaries do
        [
          build(:pbcore_rights_summary, :summary),
          build(:pbcore_rights_summary, :link)
        ]
      end

      contributors do
        [
          build(:pbcore_contributor, :with_portrayal, :with_affiliation)
        ]
      end

      asset_dates do
        [
          build(:pbcore_asset_date),
          build(:pbcore_asset_date, type: "Broadcast"),
          build(:pbcore_asset_date, type: "Copyright"),
          build(:pbcore_asset_date, type: "Created")
        ]
      end

      instantiations do
        [
          build(:pbcore_instantiation, :digital, :aapb_holding)
        ]
      end

      transient do
        other_identifiers { [:nola_code, :eidr, :local] }
      end

      after(:build) do |pbcore_description_document, evaluator|
        # Add identifiers
        Array(evaluator.other_identifiers).each do |identifier_trait|
          pbcore_description_document.identifiers << build(:pbcore_identifier, identifier_trait)
        end
      end
    end



    # ITS THE NEW
    trait :access_level_protected do
      identifiers do 
        build(:pbcore_identifier, :sony_ci_video)
        build(:pbcore_annotation, type: 'Level of User Access')

      end


    end 


    initialize_with { new(attributes) }
  end
end

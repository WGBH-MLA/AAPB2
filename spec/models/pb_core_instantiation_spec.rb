require_relative '../../app/models/pb_core_instantiation'
require_relative '../../app/models/pb_core_presenter'

describe PBCoreInstantiationPresenter do
  let(:pbc_xml) { File.read('spec/fixtures/pbcore/clean-multiple-orgs.xml') }
  let(:pbc_instantiations) { PBCorePresenter.new(pbc_xml).instantiations }
  let(:pbc_instantiation_1) { PBCoreInstantiationPresenter.new(pbc_instantiations[0]) }
  let(:pbc_instantiation_2) { PBCoreInstantiationPresenter.new(pbc_instantiations[1]) }
  let(:pbc_instantiation_3) { PBCoreInstantiationPresenter.new(pbc_instantiations[2]) }

    let(:pbc_xml) { build(:pbcore_description_document,
      asset_types: [build(:pbcore_asset_type, value: 'Program')],
      asset_dates: [build(:pbcore_asset_date, type: 'broadcast', value: '1958-00-00')],
      identifiers: [
        build(:pbcore_identifier, source: 'http://americanarchiveinventory.org', value: 'cpb-aacip/55-09j3vs0f'),
        build(:pbcore_identifier, source: 'NET_CATALOG', value: 'FMP_3185327'),
        build(:pbcore_identifier, source: 'NOLA Code', value: 'CHOT'),
      ],

      titles: [
        build(:pbcore_title, type: 'Program', value: 'Winston Churchill Obituary'),
      ],

      genres: [
        build(:pbcore_genre, annotation: 'genre', value: 'Call-in' ),
        build(:pbcore_genre, annotation: 'topic', value: 'Music' ),

        build(:pbcore_genre, annotation: "AAPB Topical Genre", value: "Biography"),
        build(:pbcore_genre, annotation: "AAPB Format Genre", value: "Documentary"),
        build(:pbcore_genre, annotation: "AAPB Format Genre", value: "Special"),
        build(:pbcore_genre, annotation: "AAPB Topical Genre", value: "Global Affairs"),
        build(:pbcore_genre, annotation: "AAPB Topical Genre", value: "War and Conflict"),
      ],


      instantiations: [
        build(:pbcore_instantiation, 
          identifiers: [
            build(:pbcore_instantiation_identifier, source: 'foo', value: 'ABC')
          ],

          dates: [
            build(:pbcore_instantiation_date, type: 'endoded', value: '2001-02-03')
          ],

          generations: [
            build(:pbcore_instantiation_generations, value: 'Copy'),
          ],

          location: build(:pbcore_instantiation_location, value: 'my closet'),
          media_type: build(:pbcore_instantiation_media_type, value: 'Moving Image')

        ),
        
        build(:pbcore_instantiation, 
          identifiers: [
            build(:pbcore_instantiation_identifier, source: 'foo', value: 'XYZ')
          ],

          dates: [
            build(:pbcore_instantiation_date, type: 'endoded', value: '2001-02-03')
          ],

          annotations: [
            build(:pbcore_instantiation_annotation, type: 'organization', value: 'Copy 1'),
          ],

          generations: [
            build(:pbcore_instantiation_generations, value: 'Access Copy'),
          ],

          colors: [
            build(:pbcore_instantiation_colors, value: 'black and white'),
          ],

          location: build(:pbcore_instantiation_location, value: 'my harddrive'),
          media_type: build(:pbcore_instantiation_media_type, value: 'Moving Image')

        ),

        build(:pbcore_instantiation, 
          identifiers: [
            build(:pbcore_instantiation_identifier, source: 'foo', value: 'PQR')
          ],

          dates: [
            build(:pbcore_instantiation_date, type: 'endoded', value: '2001-02-03')
          ],

          annotations: [
            build(:pbcore_instantiation_annotation, type: 'organization', value: 'Copy 2'),
          ],

          generations: [
            build(:pbcore_instantiation_generations, value: 'Access Copy'),
          ],

          colors: [
            build(:pbcore_instantiation_colors, value: 'black and white'),
          ],

          location: build(:pbcore_instantiation_location, value: 'my closet'),
          media_type: build(:pbcore_instantiation_media_type, value: 'Moving Image')

        ),                
      ],

      annotations: [
        build(:pbcore_annotation, type: "MAVIS Number", value: "2316780"),
        build(:pbcore_annotation, type: "organization", value: "Library of Congress"),
        build(:pbcore_annotation, type: "last_modified", value: "2018-04-11 12:07:28"),
        build(:pbcore_annotation, type: "organization", value: "KQED"),
      ]
    )}



  describe 'PBCore Instantiations' do
    it 'creates the right number of instantiations' do
      expect(pbc_instantiations.length).to eq(3)
    end
  end

  describe 'PBCore Instantiation' do
    it '#organization' do
      expect(pbc_instantiation_1.organization).to eq('KQED')
      expect(pbc_instantiation_2.organization).to eq('Library of Congress')
      expect(pbc_instantiation_3.organization).to eq('Library of Congress')
    end

    it '#identifier' do
      expect(pbc_instantiation_1.identifier).to eq('KQ61_20253;20253')
      expect(pbc_instantiation_1.identifier_source).to eq('KQED AAP')
      expect(pbc_instantiation_2.identifier).to eq('2316780')
      expect(pbc_instantiation_2.identifier_source).to eq('MAVIS Title Number')
      expect(pbc_instantiation_3.identifier).to eq('2316780')
      expect(pbc_instantiation_3.identifier_source).to eq('MAVIS Title Number')
    end

    it '#generations' do
      expect(pbc_instantiation_1.generations).to eq('Copy')
      expect(pbc_instantiation_2.generations).to eq('Access Copy')
      expect(pbc_instantiation_3.generations).to eq('Access Copy')
    end

    it '#colors' do
      expect(pbc_instantiation_1.colors).to eq(nil)
      expect(pbc_instantiation_2.colors).to eq('black and white')
      expect(pbc_instantiation_3.colors).to eq('black and white')
    end

    it '#annotations' do
      expect(pbc_instantiation_1.annotations).to eq([])
      expect(pbc_instantiation_2.annotations).to eq(['Copy 1'])
      expect(pbc_instantiation_3.annotations).to eq(['Copy 2'])
    end

    it '#format' do
      expect(pbc_instantiation_1.format).to eq('Film: 16mm')
      expect(pbc_instantiation_2.format).to eq(nil)
      expect(pbc_instantiation_3.format).to eq('mp4')
    end
  end
end

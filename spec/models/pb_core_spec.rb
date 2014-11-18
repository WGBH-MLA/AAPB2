require 'tiny_spec_helper'

describe 'Validated and plain PBCore' do

  pbc_xml = File.read('spec/fixtures/pbcore/ideal.xml')
  
  describe ValidatedPBCore do

    describe 'valid docs' do

      it 'accepts' do
        expect{ValidatedPBCore.new(pbc_xml)}.not_to raise_error
      end

    end
      
    describe 'invalid docs' do 

      it 'rejects missing closing brace' do
        invalid_pbcore = pbc_xml.sub(/>\s*$/,'')
        expect{ValidatedPBCore.new(invalid_pbcore)}.to raise_error(/missing tag start/)
      end

      it 'rejects missing closing tag' do
        invalid_pbcore = pbc_xml.sub(/<\/[^>]+>\s*$/,'')
        expect{ValidatedPBCore.new(invalid_pbcore)}.to raise_error(/Missing end tag/)
      end
      
      it 'rejects missing namespace' do
        invalid_pbcore = pbc_xml.sub(/xmlns="[^"]+"/,'')
        expect{ValidatedPBCore.new(invalid_pbcore)}.to raise_error(/Element 'pbcoreDescriptionDocument': No matching global declaration/)
      end

      it 'rejects unknown title types at creation' do
        invalid_pbcore = pbc_xml.gsub(/titleType="[^"]+"/,'titleType="unexpected"')
        expect{ValidatedPBCore.new(invalid_pbcore)}.to raise_error(/Unexpected title types: \["unexpected"\]/)
      end
      
      it 'rejects unknown media types at creation' do
        invalid_pbcore = pbc_xml.gsub(/<instantiationMediaType>[^<]+<\/instantiationMediaType>/,'<instantiationMediaType>unexpected</instantiationMediaType>')
        expect{ValidatedPBCore.new(invalid_pbcore)}.to raise_error(/Unexpected media types: \["unexpected"\]/)
      end
      
    end
    
  end

  describe PBCore do

    describe 'empty' do

      empty_pbc = PBCore.new('<pbcoreDescriptionDocument/>')

      it 'errors if no title' do
        expect{empty_pbc.title}.to raise_error('Unexpected title types: []')
      end

      it 'errors if no media_type' do
        expect{empty_pbc.media_type}.to raise_error('Unexpected media types: []')
      end

      it 'errors if no asset_type' do
        expect{empty_pbc.asset_type}.to raise_error("Expected 1 match for 'pbcoreAssetType'; got 0")
      end

    end

    describe 'full' do

      pbc = PBCore.new(pbc_xml)
      
      it 'has to_solr' do
        expect(pbc.to_solr).to eq({
            "id"=>"1234", 
            "asset_type_tesim"=>["Documentary"], 
            "asset_date_tesim"=>["2000-01-01"], 
            "titles_tesim"=>["NOVA", "Gratuitous Explosions"], 
            "title_tesim"=>["Gratuitous Explosions"], 
            "genre_tesim"=>["Horror", "Musical"], 
            "ids_tesim"=>["1234", "5678"],
            "organization_code_tesim"=>["WGBH"], 
            "rights_code_tesim"=>["PUBLIC"], 
            "media_type_tesim"=>["Moving Image"], 
            "digitized_bsi"=>true,
            "xml_ssm"=>[pbc_xml]
        })
      end

      it 'has asset_type' do
        expect(pbc.asset_type).to eq('Documentary')
      end

      it 'has asset_date' do
        expect(pbc.asset_date).to eq('2000-01-01')
      end

      it 'has titles' do
        expect(pbc.titles).to eq(['NOVA','Gratuitous Explosions'])
      end

      it 'has title' do
        expect(pbc.title).to eq('Gratuitous Explosions')
      end

      it 'has genre' do
        expect(pbc.genre).to eq(['Horror','Musical'])
      end

      it 'has id' do
        expect(pbc.id).to eq('1234')
      end

      it 'has ids' do
        expect(pbc.ids).to eq(['1234','5678'])
      end

      it 'has organization_code' do
        expect(pbc.organization_code).to eq('WGBH')
      end

      it 'has organization' do
        expect(pbc.organization).to eq(Organization.find('WGBH'))
      end

      it 'has rights_code' do
        expect(pbc.rights_code).to eq('PUBLIC')
      end

      it 'has media_type' do
        expect(pbc.media_type).to eq('Moving Image')
      end

      it 'has digitized' do
        expect(pbc.digitized).to eq(true)
      end

    end

  end
  
end
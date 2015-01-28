require 'tiny_spec_helper'

describe 'Validated and plain PBCore' do

  pbc_xml = File.read('spec/fixtures/pbcore/clean-MOCK.xml')
  
  describe ValidatedPBCore do

    describe 'valid docs' do

      Dir['spec/fixtures/pbcore/clean-*.xml'].each do |path|
        it "accepts #{File.basename(path)}" do
          expect{ValidatedPBCore.new(File.read(path))}.not_to raise_error
        end
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
      
      it 'rejects unknown media types at creation' do
        invalid_pbcore = pbc_xml.gsub(/<instantiationMediaType>[^<]+<\/instantiationMediaType>/,'<instantiationMediaType>unexpected</instantiationMediaType>')
        expect{ValidatedPBCore.new(invalid_pbcore)}.to raise_error(/Unexpected media types: \["unexpected"\]/)
      end
      
    end
    
  end

  describe PBCore do

    describe 'empty' do

      empty_pbc = PBCore.new('<pbcoreDescriptionDocument/>')

      it '"other" if no media_type' do
        expect(empty_pbc.media_type).to eq("other")
      end

      it 'nil if no asset_type' do
        expect(empty_pbc.asset_type).to eq(nil)
      end

    end

    describe 'full' do

      pbc = PBCore.new(pbc_xml)
      
      it 'has to_solr' do
        expect(pbc.to_solr).to eq({
            "id"=>"1234", 
            "text"=>["Documentary", "2000-01-01", "1234", "5678", 
              "NOVA", "Gratuitous Explosions", 
              "explosions -- gratuitious", "musicals -- horror",
              "Best episode ever!", 
              "Horror", "Musical", "Copy Left: All rights reversed.",
              "PUBLIC", "ABC", "my closet", "Sound", 
              "Not-a-Proxy", "ABC", "under the bed", "Moving Image", 
              "Proxy", "WGBH"], 
            "asset_type"=>"Documentary", 
            "asset_date"=>"2000-01-01", 
            "title"=>"Gratuitous Explosions", 
            "genre"=>["Horror", "Musical"], 
            "organization_code"=>"WGBH",
            "media_type"=>"Moving Image",
            "xml"=>pbc_xml,
            "year" => "2000"
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
        expect(pbc.organization).to eq(Organization.find_by_pbcore_name('WGBH'))
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
require_relative '../../app/models/pb_core_instantiation'
require_relative '../../app/models/pb_core'

describe PBCoreInstantiation do
  let(:pbc_xml) { File.read('spec/fixtures/pbcore/clean-multiple-orgs.xml') }
  let(:pbc_instantiations) { PBCore.new(pbc_xml).instantiations }
  let(:pbc_instantiation_1) { pbc_instantiations[0] }
  let(:pbc_instantiation_2) { pbc_instantiations[1] }
  let(:pbc_instantiation_3) { pbc_instantiations[2] }

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

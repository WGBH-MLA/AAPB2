require_relative '../../app/models/organization'

describe Organization do
  let(:wgbh) { Organization.find_by_pbcore_name('WGBH') }
  let(:loc) { Organization.find_by_pbcore_name('Library of Congress') }

  it 'contains expected data' do
    org = Organization.find_by_pbcore_name('WGBH')
    expect(org.pbcore_name).to eq('WGBH')
    expect(org.short_name).to eq('WGBH')
    expect(org.id).to eq('1784.2')
    expect(org.city).to eq('Boston')
    expect(org.state).to eq('Massachusetts')
  end

  describe '.organizations' do
    it 'returns an array of organization objects from an array of organization names' do
      expect(Organization.organizations(['WGBH', 'Library of Congress'])).to eq([wgbh, loc])
    end

    it 'filters out any organizations that cannot be found' do
      expect(Organization.organizations(['WGBH', 'Bunk Org', 'Library of Congress'])).to eq([wgbh, loc])
    end
  end

  describe '.build_organization_names_display' do
    it 'returns an array of organization short names from an array of organization objects' do
      expect(Organization.build_organization_names_display([wgbh, loc])).to eq(['WGBH', 'Library of Congress'])
    end
  end
end

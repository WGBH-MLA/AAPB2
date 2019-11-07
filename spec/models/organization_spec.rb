require_relative '../../app/models/organization'

describe Organization do
  let(:wgbh) { Organization.find_by_pbcore_name('WGBH') }
  let(:loc) { Organization.find_by_pbcore_name('Library of Congress') }

  # rubocop:disable Style/BlockDelimiters, Style/MultilineBlockLayout, Style/MultilineOperationIndentation, Style/BlockEndNewline

  let(:dirty_organization_names) { ["The Walter J. Brown Media Archives & Peabody Awards Collection at the\n" +
 "      University of Georgia"] }

  # rubocop:enable Style/BlockDelimiters, Style/MultilineBlockLayout, Style/MultilineOperationIndentation  , Style/BlockEndNewline

  it 'contains expected data' do
    org = Organization.find_by_pbcore_name('WGBH')
    expect(org.pbcore_name).to eq('WGBH')
    expect(org.short_name).to eq('WGBH')
    expect(org.id).to eq('1784.2')
    expect(org.city).to eq('Boston')
    expect(org.state).to eq('Massachusetts')
    expect(org.facet_url).to eq("/catalog?f[contributing_organizations][]=WGBH+%28MA%29")
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

  # This was an issue we were having with some pbcore.
  describe '.clean_organization_names' do
    it 'returns an array of organization short names without newlines or extra spaces' do
      expect(Organization.clean_organization_names(dirty_organization_names)).to eq(["The Walter J. Brown Media Archives & Peabody Awards Collection at the University of Georgia"])
    end
  end
end

require_relative '../../app/models/organization'

describe Organization do

  it 'works' do
    org = Organization.find_by_pbcore_name('WGBH')
    expect(org.pbcore_name).to eq('WGBH')
    expect(org.short_name).to eq('WGBH')
    expect(org.id).to eq('1784.2')
    expect(org.city).to eq('Boston')
    expect(org.state).to eq('Massachusetts')
  end

end
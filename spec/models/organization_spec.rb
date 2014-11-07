require 'tiny_spec_helper'

describe Organization do
  
  it 'works' do
    org = Organization.find('WGBH')
    expect(org.code).to eq('WGBH')
    expect(org.name).to eq('WGBH Educational Foundation')
    expect(org.state).to eq('MA')
    expect(org.to_s).to eq('WGBH Educational Foundation (MA)')
  end
  
end
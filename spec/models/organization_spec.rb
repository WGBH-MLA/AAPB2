require 'tiny_spec_helper'

describe Organization do
  
  it 'works' do
    org = Organization.find('WGBH')
    expect(org.code).to eq('WGBH')
    expect(org.state).to eq('Massachusetts')
    expect(org.to_s).to eq('WGBH (Boston, Massachusetts)')
  end
  
end
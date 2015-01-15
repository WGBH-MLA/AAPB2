require 'tiny_spec_helper'

describe Organization do
  
  it 'works' do
    org = Organization.find_by_pbcore_name('WGBH')
    expect(org.pbcore_name).to eq('WGBH')
    expect(org.id).to eq('1784.2')
    expect(org.state).to eq('Massachusetts')
    expect(org.to_s).to eq('1784.2: WGBH (Boston, Massachusetts)')
  end
  
end
require 'tiny_spec_helper'

describe Organization do
  
  it 'works' do
    org = Organization.find('WGBH')
    expect(org.id).to eq('WGBH')
    expect(org.state).to eq('Massachusetts')
    expect(org.to_s).to eq('WGBH (TODO: use full_name) (Boston, Massachusetts)')
  end
  
end
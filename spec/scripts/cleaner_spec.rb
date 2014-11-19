require_relative '../../scripts/cleaner'

describe Cleaner do
  
  it 'cleans' do
    actual = File.read('spec/fixtures/pbcore/actual-1.xml')
    clean = File.read('spec/fixtures/pbcore/clean-1.xml')
    
    expect(Cleaner.clean(actual)).to eq(clean)
  end
  
end
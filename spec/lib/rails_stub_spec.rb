describe 'Rails (module from rails_stub.rb)' do
  before do
    ActualRails = Rails
    Object.send(:remove_const, :Rails)
    load 'lib/rails_stub.rb'
  end

  after do
    Object.send(:remove_const, :Rails)
    Rails = ActualRails
    Object.send(:remove_const, :ActualRails)
  end

  it 'loads a stub Rails module' do
    expect { Rails }.not_to raise_error
  end

  describe '.root' do
    it 'returns same things as the actual Rails.root would' do
      expect(Rails.root).to eq ActualRails.root
    end
  end
end

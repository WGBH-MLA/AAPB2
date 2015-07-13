describe 'rails_stub.rb' do
  def remove_rails
    Object.send(:remove_const, :Rails)
  end
  
  it 'works' do
    expect {Rails}.not_to raise_error
    orig_root = Rails.root
    orig_rails = remove_rails
    expect {Rails}.to raise_error
    
    load 'lib/rails_stub.rb'
    expect {Rails}.not_to raise_error
    expect(Rails.root.to_s).to eq '.'
    
    remove_rails
    Rails = orig_rails
    expect(Rails.root).to eq(orig_root)
  end
end
require_relative '../../scripts/unzipper'

describe Unzipper do
  
  def unzip_sample(skip)
    unzipper = Unzipper.new(skip, 0, 'spec/fixtures/zip/*.zip')
    unzipper.map{|z| z}
  end
  
  def wrap(arr)
    arr.map{|i| "<doc>#{i}</doc>"}
  end
  
  it 'errors on 0' do
    expect{unzip_sample(0)}.to raise_error
  end
  
  # The first file is a text file and gets skipped.
  
  it 'samples 1' do
    expect(unzip_sample(1)).to eq(wrap([2,3,4,5,6]))
  end
  
  it 'samples 2' do
    expect(unzip_sample(2)).to eq(wrap([3,5]))
  end
  
  it 'samples 4' do
    expect(unzip_sample(4)).to eq(wrap([5]))
  end
  
end
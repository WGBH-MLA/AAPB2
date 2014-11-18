require 'tiny_spec_helper'

require_relative '../../scripts/unzipper'

describe Unzipper do
  
  def unzip_sample(skip)
    unzipper = Unzipper.new(skip, File.dirname(__FILE__)+'/../fixtures/zip/*.zip')
    unzipper.map{|z| z}
  end
  
  it 'errors on 0' do
    expect{unzip_sample(0)}.to raise_error
  end
  
  it 'samples 1' do
    expect(unzip_sample(1)).to eq(['1','2','3','4','5','6'])
  end
  
  it 'samples 2' do
    expect(unzip_sample(2)).to eq(['1','3','5'])
  end
  
  it 'samples 4' do
    expect(unzip_sample(4)).to eq(['1','5'])
  end
  
end
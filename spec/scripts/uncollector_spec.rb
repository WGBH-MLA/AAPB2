require_relative '../../scripts/lib/uncollector'

describe Uncollector do
  
  it '#uncollect_string' do
    x = '<x>X!</x>'
    y = '<y>Y!</y>'
    collection = "<collection>#{x}#{y}</collection>"
    
    expect(Uncollector.uncollect_string(collection)).to eq([x,y])
  end

end
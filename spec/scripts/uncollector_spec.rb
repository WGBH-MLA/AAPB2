require_relative '../../scripts/uncollector'

describe Uncollector do
  
  it '#uncollect' do
    Dir.mktmpdir {|dir|
      path = "#{dir}/collection.xml"
      x = '<x>X!</x>'
      y = '<y>Y!</y>'
      File.write(path,"<collection>#{x}#{y}</collection>")
      expect(Dir.entries(dir).sort).to eq([".", "..", "collection.xml"])
      Uncollector.uncollect(path)
      expect(Dir.entries(dir).sort).to eq([".", "..", "collection-0.xml", "collection-1.xml"])
      expect(File.read("#{dir}/collection-0.xml")).to eq(x)
      expect(File.read("#{dir}/collection-1.xml")).to eq(y)
    }
  end

end
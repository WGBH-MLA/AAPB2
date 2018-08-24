require_relative '../../scripts/lib/zipper'

describe Zipper do
  it 'reads normal files' do
    path = Rails.root + 'spec/fixtures/pbcore/clean-MOCK.xml'
    expect(Zipper.read(path)).to eq(File.read(path))
  end
  it 'reads and writes zip files' do
    content = '0123456789' * 100
    path = "/tmp/redundant-#{rand(10_000_000).to_s(36)}.txt"
    Zipper.write(path, content)
    expect(File.read(path + '.zip').length).to be < content.length / 5
    expect(Zipper.read(path+'.zip')).to eq(content)
  end
end

describe 'code style' do
  debugging = []
  merging = []

  # "vendor", in particular, is very large on Travis.
  (Dir['{app,config,scripts,spec}/**/*.{e,}rb'] - [__FILE__.gsub(/.*\/spec/, 'spec')]).each do |path|
    File.readlines(path).each_with_index do |line, i|
      combo = "#{path}:#{i}: #{line}"
      debugging << combo if line =~ /byebug|pry/
      merging << combo if line =~ /<<<|===|>>>/
    end
  end
  
  it 'has no debug cruft' do
    expect(debugging.join).to eq ''
  end

  it 'has no merge cruft' do
    expect(merging.join).to eq ''
  end
  
end

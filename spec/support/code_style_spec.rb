describe 'code style' do
  before :all do
    @debugging = []
    @merging = []

    # "vendor", in particular, is very large on Travis.
    files_to_check = (Dir['{app,config,scripts,spec}/**/*.{e,}rb'] - [__FILE__.gsub(/.*\/spec/, 'spec')])
    puts "Checking #{files_to_check.count} files for cruft..."
    files_to_check.each do |path|
      File.readlines(path).each_with_index do |line, i|
        combo = "#{path}:#{i}: #{line}"
        @debugging << combo if line =~ /byebug|pry/
        @merging << combo if line =~ /<<<|===|>>>/
      end
    end
  end

  it 'has no debug cruft' do
    expect(@debugging.join).to eq ''
  end

  it 'has no merge cruft' do
    expect(@merging.join).to eq ''
  end
end

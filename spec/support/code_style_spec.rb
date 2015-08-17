describe 'code style' do
  before :all do
    @debug = []
    @merge = []
    @error = []

    all_paths = Dir[Rails.root + '{app,config,scripts,spec}/**/*']
    paths_to_check = all_paths.reject do |path|
      path =~ /\.(jar|ico|png|gif|jpg|dat)$/ ||
      File.directory?(path) ||
      path == __FILE__
    end
    puts "Checking #{paths_to_check.count} files under #{Rails.root} for cruft..."
    paths_to_check.each do |path|
      File.readlines(path).each_with_index do |line, i|
        combo = "#{path}:#{i}: #{line}"
        begin
          @debug << combo if line =~ /byebug|pry/ && line !~ /Opry/
          @merge << combo if line =~ /^(<<<|===|>>>)/
        rescue => e
          @error << "#{path}:#{i}: #{e}"
        end
      end
    end
  end

  ['debug', 'merge', 'error'].each do |list|
    it "has no #{list} cruft" do
      joined = instance_variable_get("@#{list}").join("\n")
      expect(joined).to be_empty, joined
    end
  end
end

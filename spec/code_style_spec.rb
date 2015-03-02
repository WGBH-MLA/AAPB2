describe 'code style' do

  # "vendor", in particular, is very large on Travis.
  (Dir['{app,config,scripts,spec}/**/*.{e,}rb']-[__FILE__.gsub(/.*\/spec/,'spec')]).each do |path|
    it "has no byebug or pry in #{path}" do
      code = File.read(path)
      expect(code).not_to match 'pry'
      expect(code).not_to match 'byebug'
    end
  end

end

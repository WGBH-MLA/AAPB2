describe 'code style' do
  # TODO: scan all and collect failures: don't need to print success for each.

  # "vendor", in particular, is very large on Travis.
  (Dir['{app,config,scripts,spec}/**/*.{e,}rb'] - [__FILE__.gsub(/.*\/spec/, 'spec')]).each do |path|
    it "has no byebug or pry in #{path}" do
      code = File.read(path)
      expect(code).not_to match 'pry'
      expect(code).not_to match 'byebug'
    end
    it "has no git merge junk in #{path}" do
      code = File.read(path)
      expect(code).not_to match '<<<'
      expect(code).not_to match '>>>'
    end
  end
end

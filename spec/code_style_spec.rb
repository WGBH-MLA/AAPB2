describe 'code style' do
  
  (Dir['**/*.{e,}rb']-[__FILE__.gsub(/.*\/spec/,'spec')]).each do |path|
    it "has no byebug or pry in #{path}" do
      code = File.read(path)
      expect(code).not_to match 'pry'
      expect(code).not_to match 'byebug'
    end
  end
  
end
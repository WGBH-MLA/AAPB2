require_relative '../../scripts/cleaner'
require_relative '../../app/models/validated_pb_core'

describe Cleaner do
  
  cleaner = Cleaner.new
  
  describe 'given broken xml (but fixable)' do
    Dir['spec/fixtures/pbcore/dirty-yes-fix-*.xml'].each do |path_dirty|
      it "cleans #{File.basename(path_dirty)}" do
        path_clean = path_dirty.gsub('dirty-yes-fix', 'clean')
        dirty = File.read(path_dirty)
        clean = File.read(path_clean)

        expect(cleaner.clean(dirty)).to eq(clean)
        expect{ValidatedPBCore.new(clean)}.not_to raise_error
      end
    end
  end

  describe 'given broken xml (hopeless)' do
    Dir['spec/fixtures/pbcore/dirty-no-fix-*.xml'].each do |path_dirty|
      it "chokes on #{File.basename(path_dirty)}" do
        dirty = File.read(path_dirty)
        expect do 
          # Error could occur in either phase: we don't care.
          clean = cleaner.clean(dirty)
          ValidatedPBCore.new(clean)
        end.to raise_error
      end
    end
  end
  
end
require_relative '../../scripts/cleaner'
require_relative '../../app/models/validated_pb_core'

describe Cleaner do
  
  cleaner = Cleaner.new
  
  describe 'given broken xml (but fixable)' do
    Dir['spec/fixtures/pbcore/actual-yes-fix-*.xml'].each do |path_actual|
      it "cleans #{File.basename(path_actual)}" do
        path_clean = path_actual.gsub('actual-yes-fix', 'clean')
        actual = File.read(path_actual)
        clean = File.read(path_clean)

        expect(cleaner.clean(actual)).to eq(clean)
        expect{ValidatedPBCore.new(clean)}.not_to raise_error
      end
    end
  end

  describe 'given broken xml (hopeless)' do
    Dir['spec/fixtures/pbcore/actual-no-fix-*.xml'].each do |path_actual|
      it "chokes on #{File.basename(path_actual)}" do
        actual = File.read(path_actual)
        expect do 
          # Error could occur in either phase: we don't care.
          clean = cleaner.clean(actual)
          ValidatedPBCore.new(clean)
        end.to raise_error
      end
    end
  end
  
end
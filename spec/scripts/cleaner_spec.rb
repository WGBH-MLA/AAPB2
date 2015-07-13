require_relative '../../scripts/lib/cleaner'
require_relative '../../app/models/validated_pb_core'

describe Cleaner do
  describe 'clean-MOCK.xml' do
    it 'is in fact clean' do
      hopefully_clean = File.read('spec/fixtures/pbcore/clean-MOCK.xml')
      clean = Cleaner.new.clean(hopefully_clean, 'hopefully')
      expect(clean).to eq hopefully_clean
      expect { ValidatedPBCore.new(clean) }.not_to raise_error
    end
  end

  describe 'given dirty xml (but fixable)' do
    Dir['spec/fixtures/pbcore/dirty-yes-fix-*.xml'].each do |path_dirty|
      name = File.basename(path_dirty)
      it "cleans #{name}" do
        cleaner = Cleaner.new
        path_clean = path_dirty.gsub('dirty-yes-fix', 'clean')
        dirty = File.read(path_dirty)
        clean = File.read(path_clean)

        expect(cleaner.clean(dirty, name)).to eq(clean)
        expect { ValidatedPBCore.new(clean) }.not_to raise_error
      end
    end
  end

  describe 'given dirty xml (hopeless)' do
    Dir['spec/fixtures/pbcore/dirty-no-fix-*.xml'].each do |path_dirty|
      name = File.basename(path_dirty)
      it "chokes on #{name}" do
        cleaner = Cleaner.new
        dirty = File.read(path_dirty)

        # Error could occur either in cleaning or validation; We don't care.
        expect { ValidatedPBCore.new(cleaner.clean(dirty, name)) }.to raise_error
      end
    end
  end
  
  describe '#clean_title' do
    {
      'No change if a mix of UPPER and lower' => 'No change if a mix of UPPER and lower'
    }.each do |dirty,clean|
      it "cleans '#{dirty}'" do
        expect(Cleaner.clean_title(dirty)).to eq(clean)
      end
    end
  end
end

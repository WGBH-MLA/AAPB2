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

        path_report = path_dirty.gsub('dirty-yes-fix', 'report').gsub('.xml', '.txt')
        # To create new test:
        # File.write(path_report, cleaner.report.to_s) if !File.exist?(path_report)
        report = File.read(path_report)
        expect(cleaner.report.to_s).to eq(report)

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

        expect do
          # Error could occur in either phase: we don't care.
          clean = cleaner.clean(dirty, name)
          ValidatedPBCore.new(clean)
        end.to raise_error

        path_report = path_dirty.gsub('dirty-no-fix', 'report').gsub('.xml', '.txt')
        # To create new test:
        # File.write(path_report, cleaner.report.to_s) if !File.exist?(path_report)
        report = File.read(path_report)
        expect(cleaner.report.to_s).to eq(report)
      end
    end
  end
end

require_relative '../../scripts/lib/cleaner'
require_relative '../../app/models/validated_pb_core'

describe Cleaner do
  describe 'clean-MOCK.xml' do
    it 'is in fact clean' do
      hopefully_clean = File.read('spec/fixtures/pbcore/clean-MOCK.xml')
      clean = Cleaner.instance.clean(hopefully_clean, 'hopefully')
      expect(clean).to eq hopefully_clean
      expect { ValidatedPBCore.new(clean) }.not_to raise_error
    end
  end

  describe 'given dirty xml (but fixable)' do
    Dir['spec/fixtures/pbcore/dirty-yes-fix-*.xml'].each do |path_dirty|
      name = File.basename(path_dirty)
      it "cleans #{name}" do
        cleaner = Cleaner.instance
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
        cleaner = Cleaner.instance
        dirty = File.read(path_dirty)
        expected_first_line = File.read(path_dirty.gsub('.xml', '-error.txt'))

        # Error could occur either in cleaning or validation; We don't care.
        begin
          ValidatedPBCore.new(cleaner.clean(dirty, name))
          fail('Expected an error')
        rescue => e
          expect(e.message.split("\n").first)
            .to eq expected_first_line
          # Full paths need to be cleaned up so that they match on Travis.
        end
        # This could be shorter, but the eq matcher gives us a diff that we don't get from
        #   expect { ValidatedPBCore.new(cleaner.clean(dirty, name)) }.to raise_error(expected)
      end
    end
  end

  describe '#clean_title' do
    {
      'No change if a mix of UPPER and lower' => 'No change if a mix of UPPER and lower',
      'guesses some: xkcd, cnn, rdf, wgbh, dc' => 'Guesses Some: XKCD, CNN, RDF, WGBH, DC',
      'HARD CODED: CEO, LA, MIT, UC-DAVIS, WETA' => 'Hard Coded: CEO, LA, MIT, UC-Davis, WETA',
      'not all-knowing: ussr, cia, ianal' => 'Not All-Knowing: Ussr, Cia, Ianal',
      'AND NOTICE THE CAPITALIZATION OF "AND"' => 'And Notice the Capitalization of "and"',
      '... yet as for the in-box and the by-line' => '... yet as for the in-Box and the by-Line'
    }.each do |dirty, clean|
      it "cleans '#{clean}'" do
        expect(Cleaner.clean_title(dirty)).to eq(clean)
      end
    end
  end
end

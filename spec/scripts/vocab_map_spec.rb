require_relative '../../scripts/cleaner'

describe Cleaner::VocabMap do
  
  fixtures = File.dirname(File.dirname(__FILE__))+'/fixtures/vocab-maps'
  
  describe 'good ones' do
    
    describe 'accept' do
      [File.dirname(File.dirname(File.dirname(__FILE__)))+'/config/vocab-maps',
          fixtures].each do |dir|
        Dir["#{dir}/*"].reject{|file| file=~/bad/}.each do |yaml|
          it "accepts #{yaml}" do
            expect{Cleaner::VocabMap.new(yaml)}.not_to raise_error
          end
        end
      end
    end
    
    it 'implicitly case-normalizes' do
      map = Cleaner::VocabMap.new(fixtures+'/good-map.yml')
      expect(map.map_string('YesThisIsRight')).to eq 'yesTHISisRIGHT'
    end
    
  end
  
  describe 'bad ones' do
    
    describe 'reject' do
      [fixtures].each do |dir|
        Dir["#{dir}/*"].grep(/bad/).each do |yaml|
          it "rejects #{yaml}" do
            expect{Cleaner::VocabMap.new(yaml)}.to raise_error
          end
        end
      end
    end
    
    it 'catches case discrepancies on RHS' do
      expect{Cleaner::VocabMap.new(fixtures+'/bad-mixed-case.yml')}.to raise_error /Case discrepancy on RHS/
    end
    
    it 'catches bad yaml types' do
      expect{Cleaner::VocabMap.new(fixtures+'/bad-not-omap.yml')}.to raise_error /Unexpected datatype/
    end
    
  end
  
end
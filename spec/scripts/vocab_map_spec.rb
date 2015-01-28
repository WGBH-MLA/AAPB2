require_relative '../../scripts/cleaner'

describe Cleaner::VocabMap do
  
  fixtures = File.dirname(File.dirname(__FILE__))+'/fixtures/vocab-maps'
  
  describe 'good ones' do
    [File.dirname(File.dirname(File.dirname(__FILE__)))+'/config/vocab-maps',
        fixtures].each do |dir|
      Dir["#{dir}/*"].reject{|file| file=~/bad/}.each do |yaml|
        it "loads #{yaml}" do
          expect{Cleaner::VocabMap.new(yaml)}.not_to raise_error
        end
      end
    end
  end
  
  describe 'bad ones' do
    [fixtures].each do |dir|
      Dir["#{dir}/*"].grep(/bad/).each do |yaml|
        it "rejects #{yaml}" do
          expect{Cleaner::VocabMap.new(yaml)}.to raise_error
        end
      end
    end
  end
  
  describe 'functionality' do
    it 'implicitly case-normalizes' do
      map = Cleaner::VocabMap.new(fixtures+'/good-map.yml')
      expect(map.map_string('YesThisIsRight')).to eq 'yesTHISisRIGHT'
    end
  end
  
end
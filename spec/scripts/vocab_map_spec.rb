require_relative '../../scripts/cleaner'

describe Cleaner::VocabMap do
  
  describe 'good ones' do
    [File.dirname(File.dirname(File.dirname(__FILE__)))+'/config/vocab-maps',
        File.dirname(File.dirname(__FILE__))+'/fixtures/vocab-maps'].each do |dir|
      Dir["#{dir}/*"].reject{|file| file=~/bad/}.each do |yaml|
        it "loads #{yaml}" do
          expect{Cleaner::VocabMap.new(yaml)}.not_to raise_error
        end
      end
    end
  end
  
  describe 'bad ones' do
    [File.dirname(File.dirname(__FILE__))+'/fixtures/vocab-maps'].each do |dir|
      Dir["#{dir}/*"].grep(/bad/).each do |yaml|
        it "rejects #{yaml}" do
          expect{Cleaner::VocabMap.new(yaml)}.to raise_error
        end
      end
    end
  end
  
end
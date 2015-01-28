require_relative '../../scripts/cleaner'

describe Cleaner::VocabMap do
  
  describe 'real ones' do
    (File.dirname(File.dirname(File.dirname(__FILE__)))+'/config/vocab-maps').tap do |dir|
      Dir["#{dir}/*"].each do |yaml|
        it "loads #{yaml}" do
          expect{Cleaner::VocabMap.new(yaml)}.not_to raise_error
        end
      end
    end
  end
  
  describe 'fixtures' do
    (File.dirname(File.dirname(__FILE__))+'/fixtures/vocab-maps').tap do |dir|
      Dir["#{dir}/*"].each do |yaml|
        it "loads #{yaml}" do
          expect{Cleaner::VocabMap.new(yaml)}.not_to raise_error
        end
      end
    end
  end
  
end
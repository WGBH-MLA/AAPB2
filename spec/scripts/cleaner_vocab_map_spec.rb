require 'rexml/document'
require_relative '../../scripts/cleaner_vocab_map'

describe Cleaner::VocabMap do
  
  fixtures = File.dirname(File.dirname(__FILE__))+'/fixtures/vocab-maps'
  
  # TODO: test xml processing, particularly attribute values.
  
  describe 'when the map is good' do
    
    describe 'acceptance' do
      [File.dirname(File.dirname(File.dirname(__FILE__)))+'/config/vocab-maps',
          fixtures].each do |dir|
        Dir["#{dir}/*"].reject{|file| file=~/bad-/}.each do |yaml|
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
    
    it 'maps text nodes' do
      map = Cleaner::VocabMap.new(fixtures+'/good-map.yml')
      
      doc = REXML::Document.new('<doc><element>foo</element></doc>')
      nodes = REXML::XPath.match(doc, '/doc/element')
      map.map_node(nodes.first)
      expect(doc.to_s).to eq '<doc><element>yesTHISisRIGHT</element></doc>'
    end
    
    it 'maps attribute values' do
      map = Cleaner::VocabMap.new(fixtures+'/good-map.yml')
      
      doc = REXML::Document.new('<doc attr="foo"></doc>')
      nodes = REXML::XPath.match(doc, '/doc/@attr')
      map.map_node(nodes.first)
      expect(doc.to_s).to eq "<doc attr='yesTHISisRIGHT'/>"
    end
    
    it 'reorders by mapped attribute value' do
      card_map = Cleaner::VocabMap.new(fixtures+'/good-cardinal-map.yml')
      ord_map = Cleaner::VocabMap.new(fixtures+'/good-ordinal-map.yml')
      
      doc = REXML::Document.new(
        '<doc><el o="3.">drei</el><el o="second">two</el><el o="primo">I</el></doc>')
      
      card_map.map_nodes(REXML::XPath.match(doc, '/doc/el'))
      #expect(doc.to_s).to eq "<doc><el o='3.'>3</el><el o='second'>2</el><el o='primus'>1</el></doc>"
      
      ord_map.map_reorder_nodes(REXML::XPath.match(doc, '/doc/el/@o'))
      #expect(doc.to_s).to eq "<doc><el o='1st'>1</el><el o='2nd'>2</el><el o='3rd'>3</el></doc>"
    end
    
  end
  
  describe 'when the map is bad' do
    
    describe 'rejection' do
      [fixtures].each do |dir|
        Dir["#{dir}/*"].grep(/bad-/).each do |yaml|
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
    
    it 'catches hidden keys' do
      expect{Cleaner::VocabMap.new(fixtures+'/bad-hidden-keys.yml')}.to raise_error /Hidden keys \["ShouldNotBeRemapped"\]/
    end
    
    it 'catches hidden substring' do
      expect{Cleaner::VocabMap.new(fixtures+'/bad-hidden-substring.yml')}.to raise_error /Hidden keys \["this-prefix-hides", "hidden-by-this-suffix"\]/
    end
    
    it 'catches missing defaults' do
      expect{Cleaner::VocabMap.new(fixtures+'/bad-no-default.yml')}.to raise_error /No default mapping/
    end
    
  end
  
end
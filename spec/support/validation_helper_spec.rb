require_relative 'validation_helper'
require 'ostruct'

describe ValidationHelper do
  
  describe 'tag self closing' do

    it 'closes meta tags' do
      def page
        OpenStruct.new(body: '<html><meta attribute="value"></html>')
      end
      expect_fuzzy_xml
    end

    it 'does not close arbitrary tags' do
      def page
        OpenStruct.new(body: '<html><arbitrary attribute="value"></html>')
      end
      expect{expect_fuzzy_xml}.to raise_error
    end

  end
  
  describe 'adding attribute values' do
    
    it 'adds values' do
      def page
        OpenStruct.new(body: '<html><arbitrary attribute/></html>')
      end
      expect_fuzzy_xml
    end
    
    it 'keep previous / double quotes' do
      def page
        OpenStruct.new(body: '<html><arbitrary prev ="foo" attribute/></html>')
      end
      expect_fuzzy_xml
    end
    
    it 'keeps next / single quotes' do
      def page
        OpenStruct.new(body: '<html><arbitrary attribute next= \'bar\'/></html>')
      end
      expect_fuzzy_xml
    end
    
  end
  
end

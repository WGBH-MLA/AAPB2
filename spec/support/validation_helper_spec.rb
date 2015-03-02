require_relative 'validation_helper'
require 'ostruct'

describe ValidationHelper do

  describe 'obvious errors' do

    it 'catches mismatched tags' do
      def page
        OpenStruct.new(body: '<html><a>TEXT</b></html>')
      end
      expect { expect_fuzzy_xml }.to raise_error
    end

    it 'catches missing open brace' do
      def page
        OpenStruct.new(body: '<html>a>TEXT</a></html>')
      end
      expect { expect_fuzzy_xml }.to raise_error
    end

    it 'catches missing close brace' do
      def page
        OpenStruct.new(body: '<html><aTEXT</a></html>')
      end
      expect { expect_fuzzy_xml }.to raise_error
    end

  end

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
      expect { expect_fuzzy_xml }.to raise_error
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

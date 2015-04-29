require_relative 'validation_helper'
require 'ostruct'

describe ValidationHelper do
  class Fake < OpenStruct
    def all(_ignored)
      []
    end
  end

  describe 'obvious errors' do
    it 'catches mismatched tags' do
      def page
        Fake.new(body: '<html><a>TEXT</b></html>')
      end
      expect { expect_fuzzy_xml }.to raise_error
    end

    it 'catches missing open brace' do
      def page
        Fake.new(body: '<html>a>TEXT</a></html>')
      end
      expect { expect_fuzzy_xml }.to raise_error
    end

    it 'catches missing close brace' do
      def page
        Fake.new(body: '<html><aTEXT</a></html>')
      end
      expect { expect_fuzzy_xml }.to raise_error
    end
  end

  describe 'tag self closing' do
    it 'closes meta tags' do
      def page
        Fake.new(body: '<html><meta attribute="value"></html>')
      end
      expect_fuzzy_xml
    end

    it 'does not close arbitrary tags' do
      def page
        Fake.new(body: '<html><arbitrary attribute="value"></html>')
      end
      expect { expect_fuzzy_xml }.to raise_error
    end
  end

  describe 'adding attribute values' do
    it 'adds values' do
      def page
        Fake.new(body: '<html><arbitrary attribute/></html>')
      end
      expect_fuzzy_xml
    end

    it 'keep previous / double quotes' do
      def page
        Fake.new(body: '<html><arbitrary prev ="foo" attribute/></html>')
      end
      expect_fuzzy_xml
    end

    it 'keeps next / single quotes' do
      def page
        Fake.new(body: '<html><arbitrary attribute next= \'bar\'/></html>')
      end
      expect_fuzzy_xml
    end
    
    it 'handles iframe' do
      def page
        Fake.new(body: '<iframe src="/iframe.html" width="500" height="281" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>')
      end
    end
    
    it 'handles video' do
      # "-" in attribute name was tripping us up.
      def page
        Fake.new(body: <<END
          <video class="video-js vjs-default-skin" controls preload="none" width="400" height="300"
              poster="/poster.jpg"
              data-setup="{}">
            <source src="/media.mp4" type='video/mp4' />
            <p class="vjs-no-js">To view this video please enable JavaScript, and consider upgrading to a web browser that <a href="http://videojs.com/html5-video-support/" target="_blank">supports HTML5 video</a></p>
          </video>
END
          )
      end
      expect_fuzzy_xml
    end
  end
end

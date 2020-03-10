require 'rails_helper'

describe FormsController do

  describe '.validate_recaptcha' do
    before :all do
      # WebMock is disabled by default, but we use it for these tests.
      # Note that it is re-disabled in an :after hook below.
      WebMock.enable!
    end

    it 'handles successful response' do

    end

    it 'handles unsuccessful response' do

    end

    after(:all) do
      # Re-disable WebMock so other tests can use actual connections.
      WebMock.disable!
    end
  end
end

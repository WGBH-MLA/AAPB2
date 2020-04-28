require 'rails_helper'
require 'net/http'
require 'json'
require 'webmock'

describe FormsController do
  describe '.validate_recaptcha' do
    before :all do
      # WebMock is disabled by default, but we use it for these tests.
      # Note that it is re-disabled in an :after hook below.
      WebMock.enable!
    end

    describe '#validate_recaptcha' do
      it 'handles successful response' do
        WebMock.stub_request(:post, 'https://www.google.com/recaptcha/api/siteverify').to_return(body: "{\n" + "  \"success\": true,\n" + "  \"challenge_ts\": \"2020-03-10T18:36:28Z\",\n" + "  \"hostname\": \"localhost\",\n" + "  \"score\": 0.9,\n" + "  \"action\": \"subscribe\"\n" + "}")

        post :validate_recaptcha, "recaptcha_response" => "1234567"
        expect(JSON.parse(response.body)["status"]).to eq(200)
      end

      it 'handles unsuccessful response' do
        WebMock.stub_request(:post, 'https://www.google.com/recaptcha/api/siteverify').to_return(body: "{\n" + "  \"success\": false,\n" + "  \"challenge_ts\": \"2020-03-12T18:36:28Z\",\n" + "  \"hostname\": \"localhost\",\n" + "  \"score\": 0.3,\n" + "  \"action\": \"subscribe\"\n" + "}")

        post :validate_recaptcha, "recaptcha_response" => "1234567"
        expect(JSON.parse(response.body)["message"]).to eq("Submission method not POST or captcha blank")
        expect(JSON.parse(response.body)["status"]).to eq(403)
      end
    end

    after(:all) do
      # Re-disable WebMock so other tests can use actual connections.
      WebMock.disable!
    end
  end
end

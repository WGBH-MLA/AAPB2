require 'net/http'
require 'json'

class FormsController < ApplicationController
  def newsletter
    render 'newsletter'
  end

  def newsletter_thanks
    render 'newsletter_thanks'
  end

  def feedback
    render 'feedback'
  end

  def validate_recaptcha
    uri = URI.parse('https://www.google.com/recaptcha/api/siteverify')

    payload = {
      'secret'    => ENV["RECAPTCHA_SECRET_KEY"],
      'response'  => params["recaptcha_response"]
    }

    response = Net::HTTP.post_form(uri, payload)

    json_response = JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

    if json_response["success"] == true && json_response["score"] >= 0.5 && json_response.present?
      json_response[:status] = 200
      render json: json_response
    else
      render json: { "message" => 'Submission method not POST or captcha blank', status: 403 }
    end
  end
end

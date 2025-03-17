require 'net/http'
require 'uri'
require 'json'

class TurnstileController < ApplicationController
  skip_before_action :verify_authenticity_token # For simplicity, remove in production

  def challenge
    # Renders the Turnstile challenge page
  end

  def verify
    token = request_params['cf_turnstile_token']
    if token.nil? || token.empty?
      render json: { success: false, error: "Invalid token" }, status: :unprocessable_entity
      return
    end

    uri = URI.parse("https://challenges.cloudflare.com/turnstile/v0/siteverify")
    response = Net::HTTP.post_form(
      uri,
      "secret" => secret_key,
      "response" => turnstile_response,
      "remoteip" => request.remote_ip
    )
    result = JSON.parse(response.body)

    if result["success"]
      # Server sets the cookie in the response
      cookies.encrypted[:turnstile_verified] = {
        value: true,
        expires: 24.hours.from_now,
        secure: Rails.env.production?,
        httponly: true,
        same_site: :strict
      }

      render json: { success: true }, status: :ok
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  private

  def request_params
    JSON.parse(request.body.read)
  rescue
    {}
  end
end

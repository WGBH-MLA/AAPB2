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
      return render json: { success: false, error: "Invalid token" }, status: :unprocessable_entity
    end
  
    # Skip verification in test environment
    unless Rails.env.production?
      set_turnstile_cookie(secure: false)
      return render json: { success: true }, status: :ok
    end
  
    uri = URI.parse("https://challenges.cloudflare.com/turnstile/v0/siteverify")
    response = Net::HTTP.post_form(
      uri,
      "secret" => ENV['CLOUDFLARE_TURNSTILE_SECRET_KEY'],
      "response" => token,
      "remoteip" => request.remote_ip
    )
    result = JSON.parse(response.body)
  
    if result["success"]
      set_turnstile_cookie
      render json: { success: true }, status: :ok
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  private

  def set_turnstile_cookie(secure: Rails.env.production?)
    cookies.encrypted[:turnstile_verified] = {
      value: true,
      expires: 24.hours.from_now,
      secure: secure,
      httponly: true,
      same_site: :strict
    }
  end

  def request_params
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    {}
  end
end

require 'net/http'
require 'uri'
require 'json'

class TurnstileController < ApplicationController

  # Set how many minutes the "turnstile_verified" cookie lasts (1440 = 1 day)
  COOKIE_MINUTES = 1440

  skip_before_action :verify_authenticity_token # For simplicity, remove in production

  def challenge
    # Renders the Turnstile challenge page
  end

  def verify
    uri = URI.parse("https://challenges.cloudflare.com/turnstile/v0/siteverify")
    response = Net::HTTP.post_form(
      uri,
      secret: ENV['CLOUDFLARE_TURNSTILE_SECRET_KEY'],
      response: request_params['cf_turnstile_token'],
      remoteip: request.remote_ip
    )

    result = JSON.parse(response.body)

    if result["success"]
      # Server sets the cookie in the response to a timestamp.
      # Usage (in Controller actions):
      #   Time.now > Time.new(cookies.encrypted[:turnstile_verified])
      cookies.encrypted[:turnstile_verified] = COOKIE_MINUTES.hours.from_now

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

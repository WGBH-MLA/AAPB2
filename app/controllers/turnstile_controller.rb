require 'net/http'
require 'uri'
require 'json'

class TurnstileController < ApplicationController
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
      # Server sets the cookie in the response
      cookies.encrypted[:turnstile_verified] = {
        # Unique, opaque ID so Traefik can rate limit per verified human
        value: SecureRandom.uuid,
        expires: 2.hours.from_now,
        secure: Rails.env.production?,
        httponly: true,
        same_site: :strict
      }

      render json: { success: true }, status: :ok
    else
      render json: { success: false }, status: :unprocessable_entity
    end
  end

  # Target of the Traefik forwardAuth middleware; runs on every request, so keep it cheap.
  # Responds 200 with the Human ID in a header, or redirects to the challenge page.
  def check
    human_id = cookies.encrypted[:turnstile_verified]
    # Cookies issued before the Human ID change hold `true`, not a String
    if human_id.is_a?(String) && human_id.present?
      response.headers["X-Aapb-Human-Id"] = human_id
      head :ok
    else
      original = "#{request.headers['X-Forwarded-Proto']}://#{request.headers['X-Forwarded-Host']}#{request.headers['X-Forwarded-Uri']}"
      redirect_to turnstile_challenge_path(return_to: original)
    end
  end

  private

  def request_params
    JSON.parse(request.body.read)
  rescue
    {}
  end
end

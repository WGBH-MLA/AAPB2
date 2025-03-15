require 'net/http'
require 'uri'
require 'json'

class TurnstileController < ApplicationController
  skip_before_action :verify_authenticity_token # For simplicity, remove in production

  def challenge
    # Renders the Turnstile challenge page
  end

  def verify
    turnstile_response = params["cf-turnstile-response"]
    secret_key = "your-secret-key"
    return_to = params[:return_to] || root_path

    uri = URI.parse("https://challenges.cloudflare.com/turnstile/v0/siteverify")
    response = Net::HTTP.post_form(uri, {
      "secret" => secret_key,
      "response" => turnstile_response,
      "remoteip" => request.remote_ip
    })

    result = JSON.parse(response.body)

    if result["success"]
      session[:turnstile_verified] = true # Mark session as verified
      flash[:notice] = "Verification successful!"
      redirect_to return_to
    else
      flash[:alert] = "Verification failed. Please try again."
      redirect_to turnstile_challenge_path(return_to: return_to)
    end
  end
end

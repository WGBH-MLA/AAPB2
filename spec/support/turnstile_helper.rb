module TurnstileHelper
    def bypass_turnstile
      cookies.encrypted[:turnstile_verified] = true
    end
  end
  
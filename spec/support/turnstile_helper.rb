# This module provides helper methods for bypassing the turnstile verification in tests.
module TurnstileHelper
  def bypass_turnstile
    cookies.encrypted[:turnstile_verified] = true
  end
end
  
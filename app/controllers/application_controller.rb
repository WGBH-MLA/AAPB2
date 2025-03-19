class ApplicationController < ActionController::Base
  before_action :check_turnstile, unless: -> { Rails.env.test? }
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # Please be sure to implement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  layout 'blacklight'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def current_user
    User.new(request)
  end

  private

  def check_turnstile
    unless cookies.encrypted[:turnstile_verified]
      redirect_to turnstile_challenge_path(return_to: request.fullpath)
    end
  end
end

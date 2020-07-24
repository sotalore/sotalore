class AuthenticationController < ApplicationController
  before_action :configure_permitted_parameters
  skip_after_action :verify_authorized

  private
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end
end

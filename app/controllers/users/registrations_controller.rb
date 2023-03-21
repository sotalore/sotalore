# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  include TurnstileHelper
  include CloudflareTurnstile

  before_action :configure_permitted_parameters
  before_action :check_captcha, only: [:create] # Change this to be any actions you want to protect.

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  def check_captcha
    return if verify_turnstile(params)

    self.resource = resource_class.new sign_up_params
    resource.validate # Look for any other validation errors besides reCAPTCHA
    set_minimum_password_length

    # flash.discard(:recaptcha_error) # We need to discard flash to avoid showing it on the next page reload
    flash.now[:error] = "There was an error with bot-detection, please try again."
    render :new, status: :unprocessable_entity
  end

end

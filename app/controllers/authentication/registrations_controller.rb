# frozen_string_literal: true

class Authentication::RegistrationsController < AuthenticationController
  include TurnstileHelper
  include CloudflareTurnstile

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    return unless check_captcha

    if @user.save
      flash[:notice] = "Welcome! You have signed up successfully."
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email, :name, :password, :password_confirmation)
  end

  def check_captcha
    return true if verify_turnstile(params)

    @user.validate # Look for any other validation errors besides reCAPTCHA

    # flash.discard(:recaptcha_error) # We need to discard flash to avoid showing it on the next page reload
    flash.now[:error] = "There was an error with bot-detection, please try again."
    render :new, status: :unprocessable_entity
    false
  end

end

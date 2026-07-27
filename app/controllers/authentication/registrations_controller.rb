# frozen_string_literal: true

class Authentication::RegistrationsController < AuthenticationController
  include TurnstileHelper
  include CloudflareTurnstile

  def new
    @user = User.new
    render Views::Authentication::Registrations::New.new(user: @user)
  end

  def create
    @user = User.new(registration_params)
    return unless check_captcha

    if @user.save
      UserMailer.confirmation_instructions(@user).deliver_now
      redirect_to user_need_confirmation_path
    else
      render Views::Authentication::Registrations::New.new(user: @user), status: :unprocessable_content
    end
  end

  def need_confirmation
    render Views::Authentication::Registrations::NeedConfirmation.new
  end

  private

  def registration_params
    params.require(:user).permit(:email, :name, :password, :password_confirmation)
  end

  def check_captcha
    return true if verify_turnstile(params)

    @user.validate # Look for any other validation errors besides reCAPTCHA

    flash.now[:error] = "There was an error with bot-detection, please try again."
    render Views::Authentication::Registrations::New.new(user: @user), status: :unprocessable_content
    false
  end

end

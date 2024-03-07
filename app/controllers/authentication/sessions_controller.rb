# frozen_string_literal: true

class Authentication::SessionsController < AuthenticationController

  before_action :redirect_signed_in_user, only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    email, password = sign_in_params.values_at(:email, :password)
    @user = User.authenticate_by(email: email, password: password)
    if @user && @user.confirmed?
      sign_in_user(@user)
      redirect_to after_sign_in_path, notice: "Welcome back!"
    elsif @user # user is not confirmed, but they know their password
      flash.now.alert = "You need to confirm your account before signing in"
      render :new, status: :unprocessable_entity
    else
      @user = User.new(email: email)
      flash.now.alert = "That email or password is incorrect"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out_user
    redirect_to root_path
  end

  private

  def sign_in_params
    params.require(:user).permit(:email, :password)
  end

  def after_sign_in_path
    stored_location_for_user || root_path
  end

end

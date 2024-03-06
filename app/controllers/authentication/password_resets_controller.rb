# frozen_string_literal: true

class Authentication::PasswordResetsController < AuthenticationController
  before_action :redirect_signed_in_user
  before_action :find_user_for_update, only: %i[edit update]

  def show
  end

  def new
    @user = User.new
  end

  def create
    user = User.find_by(email: params[:user][:email])
    if user
      UserMailer.password_reset(user).deliver_later
      redirect_to action: :show
    else
      @user = User.new(email: params[:user][:email])
      @user.errors.add(:email, 'not found')
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      sign_in_user(@user)
      redirect_to root_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def find_user_for_update
    @user = User.find_by_token_for(:password_reset, params[:token])
    if @user.blank?
      flash[:alert] = "The password reset token you provided is invalid."
      redirect_to new_user_password_reset_path
    end
  end
end

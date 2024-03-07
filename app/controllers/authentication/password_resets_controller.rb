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
    email = params[:user][:email] if params[:user]
    user = User.find_by(email: email)
    if user
      UserMailer.password_reset(user).deliver_later
      redirect_to action: :show
    else
      @user = User.new(email: email)
      @user.errors.add(:email, 'not found')
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @password_reset_form = PasswordResetForm.new(@user)
  end

  def update
    @password_reset_form = PasswordResetForm.new(@user)
    if @password_reset_form.save(password_params)
      sign_in_user(@user)
      redirect_to root_path, notice: 'Your password has been updated'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:password_reset_form).permit(:password, :password_confirmation)
  end

  def find_user_for_update
    @user = User.find_by_token_for(:password_reset, params[:token])
    if @user.blank?
      flash[:alert] = "The password reset token you provided is invalid."
      redirect_to new_user_password_reset_path
    end
  end
end

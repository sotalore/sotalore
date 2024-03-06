# frozen_string_literal: true

class Authentication::ConfirmationsController < AuthenticationController

  before_action :redirect_signed_in_user

  def new
    @user = User.new
  end

  def create
    user = User.find_by(email: params[:user][:email])
    if user.present?
      UserMailer.confirmation_instructions(user).deliver_later
      redirect_to action: :resend_confirmation
    else
      @user = User.new(email: params[:user][:email])
      @user.errors.add(:email, 'not found')
      render :new, status: :unprocessable_entity
    end
  end

  def resend_confirmation
  end

  def show
    token = params[:token]

    if token
      user = User.find_by_token_for(:confirmation, token)
      if user
        user.confirm!
        flash[:notice] = "Your account has been activated, please sign in."
        redirect_to new_user_session_path
      else
        flash[:alert] = "The confirmation token you provided is invalid."
        redirect_to new_user_confirmation_path
      end
    else
      redirect_to new_user_confirmation_path
    end
  end
end

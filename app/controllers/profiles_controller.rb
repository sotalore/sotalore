# frozen_string_literal: true

class ProfilesController < ApplicationController

  before_action :authenticate_user!

  def show
    @user = current_user unless current_user.null?
    authorize @user
  end

  def update
    @user = current_user unless current_user.null?
    authorize @user
    if @user.update(user_params)
      redirect_to profile_path, notice: 'Profile updated.'
    else
      render :show
    end
  end

  private

  def user_params
    params.require(:user).permit(:picture, :picture_cache)
  end

end

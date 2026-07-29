# frozen_string_literal: true

class ProfilesController < ApplicationController

  before_action :authenticate_user!

  def show
    @user = Current.user unless Current.user.null?
    authorize @user
    render Views::Profiles::Show.new(user: @user)
  end

  def update
    @user = Current.user unless Current.user.null?
    authorize @user
    if @user.update(user_params)
      redirect_to profile_path, notice: 'Profile updated.'
    else
      render Views::Profiles::Show.new(user: @user), status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :picture, :picture_cache)
  end

end

# frozen_string_literal: true

class Adm::UsersController < AdmController

  def index
    @users = User.page(params[:page]).order('updated_at DESC')
    authorize(User)
  end

  def edit
    @user = User.find(params[:id])
    authorize(@user)
  end

  def update
    @user = User.find(params[:id])
    authorize(@user)
    @user.skip_reconfirmation!
    if @user.update(user_params)
      redirect_to adm_users_path, notice: 'User was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  protected

  def user_params
    params.require(:user).permit(:name, :email, :disabled)
  end
end

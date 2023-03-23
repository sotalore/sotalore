# frozen_string_literal: true

class Adm::UsersController < AdmController
  include SortingHelper

  SORT_FIELDS = %w[id last_request_at].freeze

  def index
    order_field, direction = get_sort_field_and_direction(SORT_FIELDS, 'id', 'desc')
    @users = User.page(params[:page]).order({ order_field => direction })
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

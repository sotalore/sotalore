# frozen_string_literal: true

class Adm::UsersController < AdmController
  SORT_FIELDS = %w[id last_request_at].freeze
  ALLOWED_DIRECTIONS = %w[asc desc].freeze

  def index
    order_field, direction = get_sort_field_and_direction(SORT_FIELDS, 'id', 'desc')
    @users = User.page(params[:page]).order({ order_field => direction })
    authorize(User)
    render Views::Adm::Users::Index.new(users: @users)
  end

  def edit
    @user = User.find(params[:id])
    authorize(@user)
    render Views::Adm::Users::Edit.new(user: @user)
  end

  def update
    @user = User.find(params[:id])
    authorize(@user)
    if @user.update(user_params)
      redirect_to adm_users_path, notice: 'User was successfully updated.'
    else
      render Views::Adm::Users::Edit.new(user: @user), status: :unprocessable_content
    end
  end

  protected

  def user_params
    params.require(:user).permit(:name, :email, :disabled)
  end

  def get_sort_field_and_direction(allowed, default, direction='asc')
    current = request.params[:sort]
    if current.present?
      field, _, dir = current.rpartition('_')
      unless allowed.include?(field)
        field = default
        dir = direction
      end
    else
      field = default
      dir = direction
    end
    dir = direction unless ALLOWED_DIRECTIONS.include?(dir)
    request.params[:sort] = "#{field}_#{dir}"
    [ field, dir ]
  end
end

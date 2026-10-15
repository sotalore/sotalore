# frozen_string_literal: true

class Adm::UsersController < AdmController
  SORT_FIELDS = %w[id last_request_at].freeze
  ALLOWED_DIRECTIONS = %w[asc desc].freeze

  def index
    order_field, direction = get_sort_field_and_direction(SORT_FIELDS, 'id', 'desc')
    @users = User.page(params[:page]).order(nulls_smallest_order(order_field, direction))
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
    attributes = user_params
    if attributes.key?(:roles)
      attributes[:roles] = attributes[:roles].compact_blank & User::ROLES
      # Don't let an admin lock themselves out.
      attributes[:roles] |= [ 'root' ] if @user == Current.user
    end
    if @user.update(attributes)
      redirect_to adm_users_path, notice: 'User was successfully updated.'
    else
      render Views::Adm::Users::Edit.new(user: @user), status: :unprocessable_content
    end
  end

  protected

  def user_params
    params.require(:user).permit(:name, :email, :disabled, roles: [])
  end

  # Treat NULL as the smallest possible value (e.g. a user who has never made a request),
  # so ascending puts NULLs first and descending puts them last. Postgres defaults to the opposite.
  def nulls_smallest_order(field, direction)
    ordering = User.arel_table[field].public_send(direction)
    direction == 'asc' ? ordering.nulls_first : ordering.nulls_last
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

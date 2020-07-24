class UserPolicy < ApplicationPolicy
  protected

  def has_view_role?
    @user.has_role?('root')
  end

  def has_edit_role?
    @user.has_role?('root')
  end

end

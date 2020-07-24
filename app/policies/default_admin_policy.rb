# frozen-string-literal: true

class DefaultAdminPolicy < ApplicationPolicy

  protected
  def has_edit_role?
    @user.has_role?('root')
  end

  def has_destroy_role?
    @user.has_role?('root')
  end

  def has_view_role?
    @user.has_role?('root')
  end

end

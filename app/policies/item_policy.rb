class ItemPolicy < ApplicationPolicy
  protected
  def has_edit_role?
    @user.has_role?('editor')
  end
end

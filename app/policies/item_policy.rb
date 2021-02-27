class ItemPolicy < ApplicationPolicy

  def by_use?
    index?
  end

  protected
  def has_edit_role?
    @user.has_role?('editor')
  end
end

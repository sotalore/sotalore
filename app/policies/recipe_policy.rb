class RecipePolicy < ApplicationPolicy

  def for_item?
    true
  end

  protected
  def has_edit_role?
    @user.has_role?('editor')
  end
end

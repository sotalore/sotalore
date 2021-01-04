class RecipePolicy < ApplicationPolicy

  def for_item?
    true
  end

  def show_partial?
    true
  end

  protected
  def has_edit_role?
    @user.has_role?('editor')
  end
end

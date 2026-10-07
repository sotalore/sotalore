class RecipePolicy < ApplicationPolicy

  def for_item?
    true
  end

  def show_partial?
    true
  end

  # Marking a recipe as no longer in the game.
  def retire?
    has_destroy_role?
  end

  # Generating a template's item and recipe variants.
  def variants?
    update?
  end

  def create_variants?
    update?
  end

  protected
  def has_edit_role?
    @user.has_role?('editor')
  end
end

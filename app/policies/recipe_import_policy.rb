# frozen-string-literal: true

class RecipeImportPolicy < DefaultAdminPolicy

  def analyze?
    update?
  end

  def apply?
    update?
  end

  def resolve_items?
    update?
  end

  def stale?
    show?
  end

  def game_keys?
    show?
  end

  def record_game_keys?
    update?
  end

  def groups?
    show?
  end

  def add_group_members?
    update?
  end

  def remove_group_members?
    update?
  end

end

# frozen-string-literal: true

# Root manages imports; AI accounts can look at them (through the read-only
# API) to find what needs cleaning up.
class RecipeImportPolicy < DefaultAdminPolicy

  def index?
    super || user.bot?
  end

  def show?
    super || user.bot?
  end

  def analyze?
    update?
  end

  def apply?
    update?
  end

  def resolve_items?
    update?
  end

  def set_full_export?
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

  def weights?
    show?
  end

  def set_weights?
    update?
  end

end

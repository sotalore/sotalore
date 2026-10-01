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

end

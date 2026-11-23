# frozen-string-literal: true

# Root manages imports; AI accounts can upload export files as new imports
# (through the API, with a token's upload scope) for root to review and apply.
class ItemCatalogImportPolicy < DefaultAdminPolicy

  def create?
    super || user.bot?
  end

  def apply?
    update?
  end

  def resolve?
    update?
  end

  def update_weights?
    update?
  end

  def remove_salvage?
    update?
  end

end

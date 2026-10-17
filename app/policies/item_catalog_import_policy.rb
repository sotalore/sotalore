# frozen-string-literal: true

class ItemCatalogImportPolicy < DefaultAdminPolicy

  def apply?
    update?
  end

  def resolve?
    update?
  end

  def remove_salvage?
    update?
  end

end

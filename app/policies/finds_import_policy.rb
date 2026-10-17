# frozen-string-literal: true

class FindsImportPolicy < DefaultAdminPolicy

  def apply?
    update?
  end

  def resolve?
    update?
  end

end

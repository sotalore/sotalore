# frozen-string-literal: true

# Root manages imports; AI accounts can upload export files as new imports
# (through the API, with a token's upload scope) for root to review and apply.
class FindsImportPolicy < DefaultAdminPolicy

  def create?
    super || user.bot?
  end

  def apply?
    update?
  end

  def resolve?
    update?
  end

end

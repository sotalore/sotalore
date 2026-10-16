# frozen-string-literal: true

# Tokens are admin-only: only root issues, lists and revokes them. A token
# can see itself (Api::V1::MeController).
class ApiTokenPolicy < DefaultAdminPolicy

  def show?
    record.is_a?(ApiToken) && record.user == user || super
  end

  def revoke?
    update?
  end

end

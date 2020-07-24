# frozen-string-literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user   = user
    @record = record
  end

  def index?
    has_view_role?
  end

  def show?
    has_view_role?
  end

  def create?
    has_edit_role?
  end

  def new?
    create?
  end

  def update?
    has_edit_role?
  end

  def edit?
    update?
  end

  def destroy?
    has_destroy_role?
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end

  protected
  def has_edit_role?
    @user.has_role?('root')
  end

  def has_destroy_role?
    @user.has_role?('root')
  end

  def has_view_role?
    true
  end
end

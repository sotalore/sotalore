class UserPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      if user.has_role?('root')
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end

  def show?
    @user == @record or super
  end

  def update?
    @user == @record or super
  end

  def destroy?
    false
  end

  protected

  def has_view_role?
    @user.has_role?('root')
  end

  def has_edit_role?
    @user.has_role?('root')
  end

end

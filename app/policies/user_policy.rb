class UserPolicy < ApplicationPolicy

  def show?
    @user == @record or super
  end

  def update?
    @user == @record or super
  end

  protected

  def has_view_role?
    @user.has_role?('root')
  end

  def has_edit_role?
    @user.has_role?('root')
  end

end

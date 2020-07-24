class CommentPolicy < ApplicationPolicy

  def create?
    true
  end

  def new?
    create?
  end

  def update?
    if record.message?
      user.has_role?('root') ||
        record.author.is?(user)
    else
      false
    end
  end

  def edit?
    update?
  end

  def destroy?
    user.has_role?('root') ||
      record.author.is?(user)
  end

  def moderate?
    user.has_role?('root')
  end

  def permitted_attributes
    if user.has_role?('root')
      [:body, :visible]
    else
      [:body]
    end
  end

end

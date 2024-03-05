class CommentPolicy < ApplicationPolicy

  def create?
    true
  end

  def new?
    create?
  end

  def update?
    if record.message?
      user.has_role?('root') || comment_authored_by_user?
    else
      false
    end
  end

  def edit?
    update?
  end

  def destroy?
    user.has_role?('root') || comment_authored_by_user?
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

  private

  def comment_authored_by_user?
    (record.author.null? && record.user_key == Current.user_key) ||
    (record.author.not_null? && record.author == user)
  end
end

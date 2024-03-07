# frozen-string-literal: true

class NullUser

  def has_role?(*args)
    false
  end
  def confirmed?
    false
  end

  def name
    'Anonymous Avatar'
  end

  def null?
    true
  end

  def not_null?
    false
  end

  def moderator?
    false
  end

  def user_recipes
    Recipe.none
  end

  def marked_for_destruction?
    false
  end
end

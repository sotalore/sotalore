# frozen-string-literal: true

class NullUser

  attr_accessor :user_key

  def initialize(user_key=nil)
    self.user_key = user_key
  end

  def has_role?(*args)
    false
  end
  def confirmed?
    false
  end

  def name
    'Anonymous Avatar'
  end

  def is?(other)
    NullUser === other &&
      self.user_key.present? &&
      self.user_key == other.user_key
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

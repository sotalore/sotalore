# frozen-string-literal: true
class Comment < ApplicationRecord

  enum :comment_type, %i[ message revision ]

  belongs_to :subject, polymorphic: true
  belongs_to :actual_author, class_name: 'User', foreign_key: 'author_id'

  scope :for_feed, ->(user) {
    if user.null?
      proxy = where('comments.visible = ? or user_key = ?', true, Current.user_key)
    elsif user.has_role?('root')
      proxy = self
    else
      proxy = where('comments.visible = ? or author_id = ?', true, user)
    end
    proxy.order(id: :desc).limit(20)
  }
  scope :most_recent, -> { order(id: :desc) }

  scope :needs_moderation, -> { where(visible: false, author_id: nil) }

  before_validation :not_visible_for_null_user
  before_validation :user_key_from_null_user

  validates :subject, :author, :body, presence: true


  def parsed_revision
    @parsed_revision ||= (revision? ? JSON::parse(body) : {})
  end

  def author
    actual_author || (@_null_user ||= NullUser.new)
  end

  def author=(val)
    if val.instance_of?(NullUser)
      @_null_user = val
    else
      self.actual_author = val
    end
  end

  def authored_by_current_user?
    (Current.user && actual_author == Current.user) ||
      (Current.user_key && user_key == Current.user_key)
  end

  def author_name
    author ? author.name : 'Anonymous Avatar'
  end

  def revision_changes
    parsed_revision['changes']
  end

  def revision_ingredient_changes
    parsed_revision['ingredient_changes']
  end

  def revision_result_changes
    parsed_revision['result_changes']
  end

  private
  def not_visible_for_null_user
    if !persisted?
      self.visible = !author.null?
    end
  end

  def user_key_from_null_user
    if author.null?
      self.user_key = Current.user_key
    end
  end
end

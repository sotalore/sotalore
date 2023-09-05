# frozen_string_literal: true

class Post < ApplicationRecord

  enum :status, { draft: 0, published: 1 }

  belongs_to :parent, polymorphic: true, optional: true
  belongs_to :author, class_name: 'User'
  has_rich_text :content

  validates :title, presence: true
  validates :author, presence: true

  def truncated(length: 300)
    self.content.body.to_plain_text.truncate(length, seperator: /\s/)
  end
end

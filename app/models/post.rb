# frozen_string_literal: true

class Post < ApplicationRecord

  enum status: { draft: 0, published: 1 }

  belongs_to :author, class_name: 'User'
  has_rich_text :content

  validates :title, presence: true
  validates :author, presence: true

  def truncated
    self.content.body.to_plain_text.truncate(600, seperator: /\s/)
  end
end

class TopPost < ApplicationRecord
  has_many :comments, as: :subject, dependent: :delete_all

  validates :key, presence: true, uniqueness: true

  def title
    key.humanize.titleize
  end

  def to_s
    title
  end
end

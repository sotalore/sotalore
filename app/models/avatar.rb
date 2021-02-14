class Avatar < ApplicationRecord

  belongs_to :user, inverse_of: :avatars
  has_many :skills, class_name: 'EarnedSkill', inverse_of: :avatar, dependent: :delete_all

  validates :name, presence: true

  before_save do
    if is_default
      user.avatars.where.not(id: id).update(is_default: false)
    end
  end
end

class Avatar < ApplicationRecord

  belongs_to :user, inverse_of: :avatars

  validates :name, presence: true

end
